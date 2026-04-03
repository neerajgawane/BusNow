require('dotenv').config();
const bcrypt = require('bcryptjs');
const pool = require('./config/db');

async function seed() {
  try {
    // Seed Route 21C: Adyar to T. Nagar (Chennai)
    await pool.query(`
      INSERT INTO routes (route_number, route_name, stops) VALUES (
        '21C', 'Adyar to T. Nagar',
        '[
          {"stop_id": 1, "name": "Adyar Signal",  "lat": 13.0067, "lng": 80.2206},
          {"stop_id": 2, "name": "Kotturpuram",   "lat": 13.0142, "lng": 80.2263},
          {"stop_id": 3, "name": "Saidapet",      "lat": 13.0201, "lng": 80.2237},
          {"stop_id": 4, "name": "T. Nagar",      "lat": 13.0418, "lng": 80.2341}
        ]'
      ) ON CONFLICT DO NOTHING
    `);
    console.log('✅ Route 21C seeded');

    // Seed Conductor Raj
    const conductorHash = await bcrypt.hash('conductor123', 10);
    await pool.query(
      `INSERT INTO users (name, phone, password_hash, role, bus_id, route_id, xp, rank)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (phone) DO NOTHING`,
      ['Conductor Raj', '9876543210', conductorHash, 'conductor', 1, 1, 120, 'Rookie Reporter']
    );
    console.log('✅ Conductor Raj seeded');

    // Seed Passenger Anil
    const passengerHash = await bcrypt.hash('passenger123', 10);
    await pool.query(
      `INSERT INTO users (name, phone, password_hash, role, xp)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (phone) DO NOTHING`,
      ['Passenger Anil', '9988776655', passengerHash, 'passenger', 0]
    );
    console.log('✅ Passenger Anil seeded');

    // Seed Bus 21C-001 (at Adyar, assigned to Raj)
    await pool.query(
      `INSERT INTO buses (bus_number, route_id, conductor_id, current_lat, current_lng, crowd_level)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT DO NOTHING`,
      ['21C-001', 1, 1, 13.0067, 80.2206, 'empty']
    );
    console.log('✅ Bus 21C-001 seeded');

    // Seed Bus 21C-002 (at Saidapet, no conductor)
    await pool.query(
      `INSERT INTO buses (bus_number, route_id, current_lat, current_lng, crowd_level)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT DO NOTHING`,
      ['21C-002', 1, 13.0201, 80.2237, 'empty']
    );
    console.log('✅ Bus 21C-002 seeded');

    console.log('\n🚌 All demo data seeded successfully!');
  } catch (err) {
    console.error('❌ Error seeding:', err.message);
  } finally {
    process.exit(0);
  }
}

seed();
