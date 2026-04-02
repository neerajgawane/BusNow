const express = require('express');
const db = require('../db');
const jwt = require('jsonwebtoken');

module.exports = (io) => {
  const router = express.Router();

  // JWT middleware
  const auth = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'No token provided' });
    try {
      req.user = jwt.verify(token, process.env.JWT_SECRET);
      next();
    } catch {
      res.status(401).json({ error: 'Invalid token' });
    }
  };

  // PATCH /api/buses/:id/crowd
  router.patch('/:id/crowd', auth, async (req, res) => {
    const { crowd_level, lat, lng } = req.body;
    const busId = req.params.id;
    try {
      await db.query(
        'UPDATE buses SET crowd_level=$1, current_lat=$2, current_lng=$3, last_updated=NOW() WHERE id=$4',
        [crowd_level, lat, lng, busId]
      );
      await db.query(
        'INSERT INTO crowd_logs (bus_id, conductor_id, crowd_level, lat, lng) VALUES ($1,$2,$3,$4,$5)',
        [busId, req.user.id, crowd_level, lat, lng]
      );

      // +10 XP for conductor
      await db.query('UPDATE users SET xp = xp + 10 WHERE id = $1', [req.user.id]);

      // Emit to all passengers watching this bus / stop
      io.emit('bus:crowd_update', { bus_id: busId, crowd_level, lat, lng });
      io.emit('bus:location_update', { bus_id: busId, lat, lng, timestamp: new Date() });

      res.json({ success: true, xp_earned: 10 });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // GET /api/buses/:id/location
  router.get('/:id/location', async (req, res) => {
    try {
      const result = await db.query(
        'SELECT current_lat, current_lng, crowd_level, last_updated FROM buses WHERE id=$1',
        [req.params.id]
      );
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // GET /api/conductor/stats
  router.get('/conductor/stats', auth, async (req, res) => {
    try {
      const result = await db.query('SELECT name, xp FROM users WHERE id=$1', [req.user.id]);
      const { name, xp } = result.rows[0];
      const rank =
        xp >= 5000 ? 'Transit Legend' :
          xp >= 2000 ? 'Road Guardian' :
            xp >= 500 ? 'Route Veteran' : 'Rookie Reporter';
      res.json({ name, xp, rank });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  return router;
};