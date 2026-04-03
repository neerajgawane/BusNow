require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const authRoutes = require('./routes/auth');
const apiRoutes = require('./routes/api');
const pool = require('./config/db');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

const JWT_SECRET = process.env.JWT_SECRET || 'supersecretjwtkey';

app.use(cors());
app.use(express.json());

// ── JWT middleware for REST routes ──────────────────────────────────────
const authenticateREST = (req, res, next) => {
  // Skip auth for login and register
  if (req.path.startsWith('/api/auth')) return next();
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Attach io to req for socket broadcasting from REST routes
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Apply JWT middleware globally, then mount routes
app.use('/api/auth', authRoutes);
app.use('/api', authenticateREST, apiRoutes);

// Health check
app.get('/', (req, res) => res.json({ status: '🚌 BusNow API running' }));

// ── Haversine distance calculation ─────────────────────────────────────
function getDistanceKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// ETA in minutes: distance / 20 km/h, capped at 60
function calcEtaMinutes(busLat, busLng, stopLat, stopLng) {
  const dist = getDistanceKm(busLat, busLng, stopLat, stopLng);
  const minutes = Math.ceil((dist / 20) * 60);
  return Math.min(60, Math.max(1, minutes));
}

// Check if current IST hour is peak: 7-10 AM or 5-8 PM
function isPeakHour() {
  const now = new Date();
  // Convert to IST (UTC+5:30)
  const istOffset = 5.5 * 60 * 60 * 1000;
  const istTime = new Date(now.getTime() + istOffset);
  const hour = istTime.getUTCHours();
  return (hour >= 7 && hour < 10) || (hour >= 17 && hour < 20);
}

// ── Rate limiting map (bus_id -> last update timestamp) ────────────────
const crowdRateLimit = new Map();

// ── Helper: broadcast ETAs to relevant stop rooms ──────────────────────
async function broadcastToStopRooms(routeId) {
  try {
    const routeRes = await pool.query('SELECT stops FROM routes WHERE id = $1', [routeId]);
    if (routeRes.rows.length === 0) return;
    const stops = routeRes.rows[0].stops;

    const busesRes = await pool.query(
      'SELECT id, bus_number, current_lat, current_lng, crowd_level FROM buses WHERE route_id = $1',
      [routeId]
    );

    for (const stop of stops) {
      const incomingBuses = busesRes.rows.map((b) => ({
        bus_id: b.id,
        bus_number: b.bus_number,
        crowd_level: b.crowd_level,
        eta_minutes: calcEtaMinutes(b.current_lat, b.current_lng, stop.lat, stop.lng),
        lat: b.current_lat,
        lng: b.current_lng,
      }));
      incomingBuses.sort((a, b) => a.eta_minutes - b.eta_minutes);
      io.to(`stop:${stop.stop_id}`).emit('stop:incoming_buses', incomingBuses);
    }
  } catch (e) {
    console.error('broadcastToStopRooms error:', e.message);
  }
}

// ── Socket.io JWT authentication middleware ─────────────────────────────
io.use((socket, next) => {
  const token = socket.handshake.auth?.token;
  if (token) {
    try {
      socket.user = jwt.verify(token, JWT_SECRET);
    } catch {
      // Allow unauthenticated connections for passengers who haven't logged in yet
      console.log('Socket auth: invalid token, allowing anonymous');
    }
  }
  next();
});

// ── Socket.io real-time logic ──────────────────────────────────────────
io.on('connection', (socket) => {
  console.log(`🔌 Socket connected: ${socket.id} (user: ${socket.user?.id || 'anonymous'})`);

  // Passenger subscribes to a stop room
  socket.on('stop:subscribe', async (payload) => {
    if (!payload?.stop_id) return;
    const stopId = payload.stop_id;
    const roomName = `stop:${stopId}`;
    socket.join(roomName);
    console.log(`📍 Socket ${socket.id} joined ${roomName}`);

    // Immediately send current bus data for this stop
    try {
      const routesRes = await pool.query(
        "SELECT id, stops FROM routes WHERE stops @> $1::jsonb",
        [JSON.stringify([{ stop_id: stopId }])]
      );

      if (routesRes.rows.length > 0) {
        let allBuses = [];
        for (const route of routesRes.rows) {
          const targetStop = route.stops.find((s) => s.stop_id === stopId);
          if (!targetStop) continue;

          const busesRes = await pool.query(
            'SELECT id, bus_number, current_lat, current_lng, crowd_level FROM buses WHERE route_id = $1',
            [route.id]
          );

          const incoming = busesRes.rows.map((b) => ({
            bus_id: b.id,
            bus_number: b.bus_number,
            crowd_level: b.crowd_level,
            eta_minutes: calcEtaMinutes(b.current_lat, b.current_lng, targetStop.lat, targetStop.lng),
            lat: b.current_lat,
            lng: b.current_lng,
          }));
          allBuses.push(...incoming);
        }
        allBuses.sort((a, b) => a.eta_minutes - b.eta_minutes);
        socket.emit('stop:incoming_buses', allBuses);
      }
    } catch (e) {
      console.error('stop:subscribe error:', e.message);
    }
  });

  // Conductor joins their bus room
  socket.on('bus:join', (payload) => {
    if (!payload?.bus_id) return;
    socket.join(`bus:${payload.bus_id}`);
    console.log(`🚌 Socket ${socket.id} joined bus:${payload.bus_id}`);
  });

  // Conductor emits crowd update via socket
  socket.on('bus:crowd_update', async (payload) => {
    const { bus_id, crowd_level, lat, lng } = payload || {};
    if (!bus_id || !crowd_level) return;

    // Rate limit: 1 update per 10 seconds per bus
    const now = Date.now();
    const lastUpdate = crowdRateLimit.get(bus_id) || 0;
    if (now - lastUpdate < 10000) {
      socket.emit('error', { message: 'Rate limited: wait 10 seconds between updates' });
      return;
    }
    crowdRateLimit.set(bus_id, now);

    try {
      // Update bus in DB
      await pool.query(
        'UPDATE buses SET crowd_level = $1, current_lat = $2, current_lng = $3, last_updated = NOW() WHERE id = $4',
        [crowd_level, lat, lng, bus_id]
      );

      // Log to crowd_logs
      const conductorId = socket.user?.id || null;
      if (conductorId) {
        await pool.query(
          'INSERT INTO crowd_logs (bus_id, conductor_id, crowd_level, lat, lng) VALUES ($1, $2, $3, $4, $5)',
          [bus_id, conductorId, crowd_level, lat, lng]
        );

        // Award XP
        let xpGained = 10;
        if (isPeakHour()) xpGained += 15;

        // Update XP and streak
        const today = new Date().toISOString().slice(0, 10);
        await pool.query(
          `UPDATE users SET xp = xp + $1,
           streak_days = CASE
             WHEN last_update_date = CURRENT_DATE - INTERVAL '1 day' THEN streak_days + 1
             WHEN last_update_date = CURRENT_DATE THEN streak_days
             ELSE 1
           END,
           last_update_date = CURRENT_DATE
           WHERE id = $2`,
          [xpGained, conductorId]
        );

        // Update rank based on new XP
        const xpRes = await pool.query('SELECT xp FROM users WHERE id = $1', [conductorId]);
        if (xpRes.rows.length > 0) {
          const totalXp = xpRes.rows[0].xp;
          let rank = 'Rookie Reporter';
          if (totalXp >= 5000) rank = 'Transit Legend';
          else if (totalXp >= 2000) rank = 'Road Guardian';
          else if (totalXp >= 500) rank = 'Route Veteran';
          await pool.query('UPDATE users SET rank = $1 WHERE id = $2', [rank, conductorId]);
        }
      }

      // Broadcast crowd update to bus room and globally
      io.to(`bus:${bus_id}`).emit('bus:crowd_update', { bus_id, crowd_level, lat, lng });

      // Broadcast updated ETAs to relevant stop rooms
      const busRoute = await pool.query('SELECT route_id FROM buses WHERE id = $1', [bus_id]);
      if (busRoute.rows.length > 0) {
        await broadcastToStopRooms(busRoute.rows[0].route_id);
      }
    } catch (e) {
      console.error('bus:crowd_update error:', e.message);
    }
  });

  // Conductor emits GPS location update
  socket.on('bus:location_update', async (payload) => {
    const { bus_id, lat, lng } = payload || {};
    if (!bus_id || lat == null || lng == null) return;

    try {
      await pool.query(
        'UPDATE buses SET current_lat = $1, current_lng = $2, last_updated = NOW() WHERE id = $3',
        [lat, lng, bus_id]
      );

      // Broadcast location to bus watchers
      io.to(`bus:${bus_id}`).emit('bus:location_update', { bus_id, lat, lng, timestamp: new Date().toISOString() });

      // Recalculate and broadcast ETAs to stop rooms
      const busRoute = await pool.query('SELECT route_id FROM buses WHERE id = $1', [bus_id]);
      if (busRoute.rows.length > 0) {
        await broadcastToStopRooms(busRoute.rows[0].route_id);
      }
    } catch (e) {
      console.error('bus:location_update error:', e.message);
    }
  });

  socket.on('disconnect', () => {
    console.log(`❌ Socket disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚌 BusNow backend running on port ${PORT}`);
});
