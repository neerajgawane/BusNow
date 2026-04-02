const express = require('express');
const router = express.Router();
const db = require('../db');

// GET /api/routes/:id/stops
router.get('/:id/stops', async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM routes WHERE id=$1', [req.params.id]);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/routes (all routes)
router.get('/', async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM routes');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;