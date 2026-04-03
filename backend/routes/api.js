const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const jwt = require('jsonwebtoken');

const authenticate = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'supersecretjwtkey');
    req.user = decoded;
    next();
  } catch {
    res.status(401).json({ error: 'Unauthorized' });
  }
};

router.get('/routes/:id/stops', async (req, res) => {
  try {
    const result = await pool.query('SELECT stops FROM routes WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Route not found' });
    res.json(result.rows[0].stops);
  } catch (err) { res.status(500).json({ error: 'Server error' }); }
});

router.patch('/buses/:id/crowd', authenticate, async (req, res) => {
  const { crowd_level, lat, lng } = req.body;
  try {
    const busRes = await pool.query(
      'UPDATE buses SET crowd_level = $1, current_lat = $2, current_lng = $3, last_updated = NOW() WHERE id = $4 RETURNING *',
      [crowd_level, lat, lng, req.params.id]
    );
    if (busRes.rows.length === 0) return res.status(404).json({ error: 'Bus not found' });
    
    // Log crowd dynamically
    await pool.query(
      'INSERT INTO crowd_logs (bus_id, conductor_id, crowd_level, lat, lng) VALUES ($1, $2, $3, $4, $5)',
      [req.params.id, req.user.id, crowd_level, lat, lng]
    );
    
    // Add XP to the conductor
    await pool.query('UPDATE users SET xp = xp + 10 WHERE id = $1', [req.user.id]);
    
    // Broadcast via global socket
    req.io.emit('bus:crowd_update', { bus_id: parseInt(req.params.id), crowd_level, lat, lng });
    
    res.json({ message: 'Success', bus: busRes.rows[0] });
  } catch (err) { res.status(500).json({ error: 'Server error' }); }
});

// Calculate ETAs
function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
    var R = 6371; var dLat = (lat2-lat1) * (Math.PI/180); var dLon = (lon2-lon1) * (Math.PI/180); 
    var a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(lat1 * (Math.PI/180)) * Math.cos(lat2 * (Math.PI/180)) * Math.sin(dLon/2) * Math.sin(dLon/2); 
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); return R * c;
}

router.get('/stops/:id/buses', async (req, res) => {
  try {
     const stopId = parseInt(req.params.id);
     
     // Quick json path match
     const routesRes = await pool.query('SELECT id, stops FROM routes WHERE stops @> $1', [`[{"stop_id": ${stopId}}]`]);
     
     if (routesRes.rows.length === 0) return res.json([]);
     
     let allIncoming = [];
     for(const r of routesRes.rows) {
        const targetStop = r.stops.find(s => s.stop_id === stopId);
        const busesRes = await pool.query('SELECT id, current_lat, current_lng, crowd_level FROM buses WHERE route_id = $1', [r.id]);
        
        const incoming = busesRes.rows.map(b => {
            let dist = 5;
            if(b.current_lat && targetStop.lat) {
               dist = getDistanceFromLatLonInKm(b.current_lat, b.current_lng, targetStop.lat, targetStop.lng);
            }
            return {
               bus_id: b.id,
               eta_minutes: Math.max(1, Math.ceil((dist / 30) * 60)), // 30km/h avg
               crowd_level: b.crowd_level
            };
        });
        allIncoming.push(...incoming);
     }
     
     res.json(allIncoming);
  } catch (err) { console.error(err); res.status(500).json({ error: 'Server error' }); }
});

router.get('/buses/:id/location', async (req, res) => {
  try {
    const result = await pool.query('SELECT current_lat, current_lng, last_updated FROM buses WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: 'Server error' }); }
});

router.get('/conductor/stats', authenticate, async (req, res) => {
  try {
    const userRes = await pool.query('SELECT xp FROM users WHERE id = $1', [req.user.id]);
    if (userRes.rows.length === 0) return res.status(404).json({ error: 'Not found' });
    const xp = userRes.rows[0].xp;
    
    let rank = 'Rookie Reporter';
    if(xp >= 5000) rank = 'Transit Legend';
    else if(xp >= 2000) rank = 'Road Guardian';
    else if(xp >= 500) rank = 'Route Veteran';
    
    const badges = [];
    if(xp > 10) badges.push('First Update');
    if(xp > 100) badges.push('Route Expert');
    if(xp > 500) badges.push('Top Conductor');

    res.json({ xp, rank, badges });
  } catch (err) { res.status(500).json({ error: 'Server error' }); }
});

module.exports = router;
