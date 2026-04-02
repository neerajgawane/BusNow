const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { phone, password } = req.body;
  try {
    const result = await db.query('SELECT * FROM users WHERE phone = $1', [phone]);
    const user = result.rows[0];
    if (!user) return res.status(401).json({ error: 'User not found' });

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign(
      { id: user.id, role: user.role, bus_id: user.bus_id, route_id: user.route_id },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: { id: user.id, name: user.name, role: user.role, bus_id: user.bus_id, xp: user.xp }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/register
router.post('/register', async (req, res) => {
  const { name, phone, password } = req.body;
  
  // Hackathon Trick: Automatically assign the 'conductor' role and Bus 21C if the user is named "Conductor Raj" or contains "Conductor"
  const determinedRole = name.toLowerCase().includes('conductor') ? 'conductor' : 'passenger';
  const determinedBusId = determinedRole === 'conductor' ? 1 : null; 
  const determinedRouteId = determinedRole === 'conductor' ? 1 : null;
  
  try {
    const hash = await bcrypt.hash(password, 10);
    const result = await db.query(
      'INSERT INTO users (name, phone, password_hash, role, bus_id, route_id) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id, name, role',
      [name, phone, hash, determinedRole, determinedBusId, determinedRouteId]
    );
    res.json({ success: true, user: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;