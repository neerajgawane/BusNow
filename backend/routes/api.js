const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const jwt = require('jsonwebtoken');

// ── Haversine distance ─────────────────────────────────────────────────
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

function calcEtaMinutes(busLat, busLng, stopLat, stopLng) {
  const dist = getDistanceKm(busLat, busLng, stopLat, stopLng);
  const minutes = Math.ceil((dist / 20) * 60); // 20 km/h average
  return Math.min(60, Math.max(1, minutes));
}

function isPeakHour() {
  const now = new Date();
  const istOffset = 5.5 * 60 * 60 * 1000;
  const istTime = new Date(now.getTime() + istOffset);
  const hour = istTime.getUTCHours();
  return (hour >= 7 && hour < 10) || (hour >= 17 && hour < 20);
}

// Rate limit map (bus_id -> timestamp)
const crowdRateLimit = new Map();

// ── GET /api/routes/:id/stops ──────────────────────────────────────────
router.get('/routes/:id/stops', async (req, res) => {
  try {
    const result = await pool.query('SELECT stops FROM routes WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Route not found' });
    res.json(result.rows[0].stops);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── GET /api/routes ────────────────────────────────────────────────────
router.get('/routes', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM routes');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── PATCH /api/buses/:id/crowd ─────────────────────────────────────────
router.patch('/buses/:id/crowd', async (req, res) => {
  const { crowd_level, lat, lng } = req.body;
  const busId = parseInt(req.params.id);

  if (!crowd_level) return res.status(400).json({ error: 'crowd_level is required' });
  if (!['empty', 'moderate', 'full', 'overcrowded'].includes(crowd_level)) {
    return res.status(400).json({ error: 'Invalid crowd_level' });
  }

  // Rate limit: 1 update per 10 seconds per bus
  const now = Date.now();
  const lastUpdate = crowdRateLimit.get(busId) || 0;
  if (now - lastUpdate < 10000) {
    return res.status(429).json({ error: 'Rate limited: wait 10 seconds between updates' });
  }
  crowdRateLimit.set(busId, now);

  try {
    const busRes = await pool.query(
      'UPDATE buses SET crowd_level = $1, current_lat = $2, current_lng = $3, last_updated = NOW() WHERE id = $4 RETURNING *',
      [crowd_level, lat, lng, busId]
    );
    if (busRes.rows.length === 0) return res.status(404).json({ error: 'Bus not found' });

    // Log to crowd_logs
    await pool.query(
      'INSERT INTO crowd_logs (bus_id, conductor_id, crowd_level, lat, lng) VALUES ($1, $2, $3, $4, $5)',
      [busId, req.user.id, crowd_level, lat, lng]
    );

    // Award XP (base +10, peak hour +15)
    let xpGained = 10;
    if (isPeakHour()) xpGained += 15;

    // Update XP, streak, and last_update_date
    await pool.query(
      `UPDATE users SET xp = xp + $1,
       streak_days = CASE
         WHEN last_update_date = CURRENT_DATE - INTERVAL '1 day' THEN streak_days + 1
         WHEN last_update_date = CURRENT_DATE THEN streak_days
         ELSE 1
       END,
       last_update_date = CURRENT_DATE
       WHERE id = $2`,
      [xpGained, req.user.id]
    );

    // Update rank based on new XP
    const xpRes = await pool.query('SELECT xp FROM users WHERE id = $1', [req.user.id]);
    if (xpRes.rows.length > 0) {
      const totalXp = xpRes.rows[0].xp;
      let rank = 'Rookie Reporter';
      if (totalXp >= 5000) rank = 'Transit Legend';
      else if (totalXp >= 2000) rank = 'Road Guardian';
      else if (totalXp >= 500) rank = 'Route Veteran';
      await pool.query('UPDATE users SET rank = $1 WHERE id = $2', [rank, req.user.id]);
    }

    // Broadcast via Socket.io to bus room and stop rooms
    req.io.to(`bus:${busId}`).emit('bus:crowd_update', { bus_id: busId, crowd_level, lat, lng });

    // Broadcast updated ETAs to relevant stop rooms
    const routeId = busRes.rows[0].route_id;
    if (routeId) {
      const routeRes = await pool.query('SELECT stops FROM routes WHERE id = $1', [routeId]);
      if (routeRes.rows.length > 0) {
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
          req.io.to(`stop:${stop.stop_id}`).emit('stop:incoming_buses', incomingBuses);
        }
      }
    }

    res.json({ message: 'Success', bus: busRes.rows[0], xp_earned: xpGained });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── GET /api/stops/:id/buses ───────────────────────────────────────────
router.get('/stops/:id/buses', async (req, res) => {
  try {
    const stopId = parseInt(req.params.id);

    const routesRes = await pool.query(
      "SELECT id, stops FROM routes WHERE stops @> $1::jsonb",
      [JSON.stringify([{ stop_id: stopId }])]
    );

    if (routesRes.rows.length === 0) return res.json([]);

    let allIncoming = [];
    for (const r of routesRes.rows) {
      const targetStop = r.stops.find((s) => s.stop_id === stopId);
      if (!targetStop) continue;

      const busesRes = await pool.query(
        'SELECT id, bus_number, current_lat, current_lng, crowd_level FROM buses WHERE route_id = $1',
        [r.id]
      );

      const incoming = busesRes.rows.map((b) => ({
        bus_id: b.id,
        bus_number: b.bus_number,
        crowd_level: b.crowd_level,
        eta_minutes: calcEtaMinutes(b.current_lat, b.current_lng, targetStop.lat, targetStop.lng),
        lat: b.current_lat,
        lng: b.current_lng,
        recommendation: ['empty', 'moderate'].includes(b.crowd_level) ? 'BOARD' : 'WAIT',
      }));
      allIncoming.push(...incoming);
    }

    allIncoming.sort((a, b) => a.eta_minutes - b.eta_minutes);
    res.json(allIncoming);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── GET /api/buses/:id/location ────────────────────────────────────────
router.get('/buses/:id/location', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT current_lat, current_lng, last_updated FROM buses WHERE id = $1',
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Bus not found' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── GET /api/conductor/stats ───────────────────────────────────────────
router.get('/conductor/stats', async (req, res) => {
  try {
    const userRes = await pool.query(
      'SELECT xp, rank, streak_days FROM users WHERE id = $1',
      [req.user.id]
    );
    if (userRes.rows.length === 0) return res.status(404).json({ error: 'User not found' });

    const { xp, rank, streak_days } = userRes.rows[0];

    // Count total updates
    const countRes = await pool.query(
      'SELECT COUNT(*) as total FROM crowd_logs WHERE conductor_id = $1',
      [req.user.id]
    );
    const totalUpdates = parseInt(countRes.rows[0].total);

    // Compute badges
    const badges = [];
    if (totalUpdates >= 10) badges.push('Route Expert');
    if (totalUpdates >= 50) badges.push('Peak Warrior');
    if (streak_days >= 7) badges.push('Zero Miss Week');
    if (xp >= 1000) badges.push('Top Conductor');

    res.json({
      xp,
      rank,
      badges,
      total_updates: totalUpdates,
      streak_days: streak_days || 0,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
