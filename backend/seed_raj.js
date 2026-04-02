require('dotenv').config();
const bcrypt = require('bcryptjs');
const db = require('./src/db'); // the app uses db.js

async function seed() {
  try {
    const hash = await bcrypt.hash('password123', 10);
    await db.query(
      "INSERT INTO users (name, phone, password_hash, role, bus_id, route_id) VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (phone) DO NOTHING",
      ['Conductor Raj', '9999999999', hash, 'conductor', 1, 1]
    );
    console.log('Successfully seeded Conductor Raj!');
  } catch (err) {
    console.error('Error seeding:', err.message);
  } finally {
    process.exit(0);
  }
}
seed();
