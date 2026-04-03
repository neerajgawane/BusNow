const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'supersecretjwtkey';

router.post('/register', async (req, res) => {
  const { name, phone, password } = req.body;
  try {
    const hashed = await bcrypt.hash(password, 10);
    const result = await pool.query(
      'INSERT INTO users (name, phone, role, password_hash) VALUES ($1, $2, $3, $4) RETURNING id, name, phone, role',
      [name, phone, 'passenger', hashed]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.constraint === 'users_phone_key') return res.status(400).json({ error: 'Phone auto registered' });
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/login', async (req, res) => {
  const { phone, password, role } = req.body;
  try {
    // Query by phone; optionally filter by role if provided
    let result;
    if (role) {
      result = await pool.query('SELECT * FROM users WHERE phone = $1 AND role = $2', [phone, role]);
    } else {
      result = await pool.query('SELECT * FROM users WHERE phone = $1', [phone]);
    }
    if (result.rows.length === 0) return res.status(401).json({ error: 'Invalid credentials' });
    
    const user = result.rows[0];
    const isValid = await bcrypt.compare(password, user.password_hash);
    
    if (!isValid) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign(
      { id: user.id, role: user.role, bus_id: user.bus_id, route_id: user.route_id },
      JWT_SECRET,
      { expiresIn: '30d' }
    );
    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        role: user.role,
        phone: user.phone,
        bus_id: user.bus_id,
        route_id: user.route_id,
        xp: user.xp || 0,
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
