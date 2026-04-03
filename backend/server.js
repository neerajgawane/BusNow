require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const apiRoutes = require('./routes/api');
const pool = require('./config/db');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use(cors());
app.use(express.json());

// Attach io to req
app.use((req, res, next) => {
  req.io = io;
  next();
});

// REST Routes
app.use('/api/auth', authRoutes);
app.use('/api', apiRoutes);

// Simple mock haversine distance for ETA Calculation
function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
  var R = 6371; 
  var dLat = (lat2-lat1) * (Math.PI/180);
  var dLon = (lon2-lon1) * (Math.PI/180); 
  var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
          Math.cos(lat1 * (Math.PI/180)) * Math.cos(lat2 * (Math.PI/180)) * 
          Math.sin(dLon/2) * Math.sin(dLon/2); 
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
  return R * c;
}

// Socket.io real-time logic
io.on('connection', (socket) => {
  console.log(`Socket connected: ${socket.id}`);

  // Passenger emits to subscribe to a stop
  socket.on('stop:subscribe', async (payload) => {
    if (payload && payload.stop_id) {
       const roomName = `stop_${payload.stop_id}`;
       socket.join(roomName);
       console.log(`Socket ${socket.id} joined ${roomName}`);
       
       // Immediately send mocked incoming buses
       try {
           const routesRes = await pool.query('SELECT id, stops FROM routes WHERE stops @> $1', [`[{"stop_id": ${payload.stop_id}}]`]);
           if (routesRes.rows.length > 0) {
               const routeId = routesRes.rows[0].id;
               const stopsList = routesRes.rows[0].stops;
               const targetStop = stopsList.find(s => s.stop_id === payload.stop_id);
               
               const busesRes = await pool.query('SELECT id, current_lat, current_lng, crowd_level FROM buses WHERE route_id = $1', [routeId]);
               const incomingBuses = busesRes.rows.map(b => {
                 let dist = 3.0; // Math mock default
                 if(b.current_lat && targetStop.lat) {
                    dist = getDistanceFromLatLonInKm(b.current_lat, b.current_lng, targetStop.lat, targetStop.lng);
                 }
                 return {
                     bus_id: b.id,
                     eta_minutes: Math.max(1, Math.ceil((dist / 30) * 60)), // Assuming 30 km/h average bus speed
                     crowd_level: b.crowd_level
                 };
               });
               
               socket.emit('stop:incoming_buses', incomingBuses);
           }
       } catch(e) { console.error('Subscription error:', e); }
    }
  });

  // Conductor emits crowd updates (also supported via API)
  socket.on('bus:crowd_update', (payload) => {
    io.emit('bus:crowd_update', payload);
  });

  // Conductor emits gps updates
  socket.on('bus:location_update', async (payload) => {
    const { bus_id, lat, lng } = payload;
    io.emit('bus:location_update', payload);
     try {
         // Persist GPS
         await pool.query(
             'UPDATE buses SET current_lat = $1, current_lng = $2, last_updated = NOW() WHERE id = $3',
             [lat, lng, bus_id]
         );
     } catch (e) {
         console.error('Location update error:', e);
     }
  });

  socket.on('disconnect', () => {
    console.log(`Socket disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend server running on port ${PORT}`);
});
