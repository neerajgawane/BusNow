const express = require('express');
const router = express.Router();
const db = require('../db');

// GET /api/stops/:id/buses
router.get('/:id/buses', async (req, res) => {
  const stopId = parseInt(req.params.id);
  try {
    const result = await db.query(`
      SELECT b.id, b.bus_number, b.crowd_level, b.current_lat, b.current_lng,
             r.stops, r.route_name, r.route_number
      FROM buses b
      JOIN routes r ON b.route_id = r.id
    `);

    const buses = result.rows
      .filter(bus => bus.stops.some(s => s.stop_id === stopId))
      .map(bus => {
        const stops = bus.stops;
        const stopIdx = stops.findIndex(s => s.stop_id === stopId);
        const etaMinutes = stopIdx >= 0 ? Math.max(1, stopIdx * 4) : 10;
        return {
          bus_id: bus.id,
          bus_number: bus.bus_number,
          route_name: bus.route_name,
          route_number: bus.route_number,
          crowd_level: bus.crowd_level,
          eta_minutes: etaMinutes,
          recommendation: ['empty', 'moderate'].includes(bus.crowd_level) ? 'BOARD' : 'WAIT',
        };
      });

    res.json(buses);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;