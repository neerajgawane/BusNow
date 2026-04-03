CREATE TYPE crowd_level_enum AS ENUM ('empty', 'moderate', 'full', 'overcrowded');
CREATE TYPE user_role_enum AS ENUM ('conductor', 'passenger');

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(15) UNIQUE NOT NULL,
  role user_role_enum NOT NULL,
  bus_id INTEGER,
  route_id INTEGER,
  password_hash TEXT NOT NULL,
  xp INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS routes (
  id SERIAL PRIMARY KEY,
  route_number VARCHAR(20) NOT NULL,
  route_name VARCHAR(100) NOT NULL,
  stops JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS buses (
  id SERIAL PRIMARY KEY,
  bus_number VARCHAR(20) NOT NULL,
  route_id INTEGER REFERENCES routes(id),
  conductor_id INTEGER REFERENCES users(id),
  current_lat DOUBLE PRECISION,
  current_lng DOUBLE PRECISION,
  crowd_level crowd_level_enum DEFAULT 'empty',
  last_updated TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS crowd_logs (
  id SERIAL PRIMARY KEY,
  bus_id INTEGER REFERENCES buses(id),
  conductor_id INTEGER REFERENCES users(id),
  crowd_level crowd_level_enum NOT NULL,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  timestamp TIMESTAMP DEFAULT NOW()
);

-- ===== SEED DATA =====

-- Route 1: Mumbai - Dadar to Andheri (real bus corridor)
INSERT INTO routes (route_number, route_name, stops) VALUES (
  '330',
  'Dadar to Andheri',
  '[
    {"stop_id": 1, "name": "Dadar Station",     "lat": 19.0178, "lng": 72.8478},
    {"stop_id": 2, "name": "Mahim Junction",    "lat": 19.0368, "lng": 72.8397},
    {"stop_id": 3, "name": "Bandra Bus Depot",  "lat": 19.0544, "lng": 72.8403},
    {"stop_id": 4, "name": "Khar Station",      "lat": 19.0726, "lng": 72.8369},
    {"stop_id": 5, "name": "Andheri Station",   "lat": 19.1197, "lng": 72.8464}
  ]'
) ON CONFLICT DO NOTHING;

-- Route 2: Mumbai - Borivali to Churchgate
INSERT INTO routes (route_number, route_name, stops) VALUES (
  '451',
  'Borivali to Churchgate',
  '[
    {"stop_id": 1, "name": "Borivali Station",   "lat": 19.2295, "lng": 72.8568},
    {"stop_id": 2, "name": "Kandivali Station",  "lat": 19.2048, "lng": 72.8524},
    {"stop_id": 3, "name": "Goregaon Station",   "lat": 19.1663, "lng": 72.8494},
    {"stop_id": 4, "name": "Andheri Station",    "lat": 19.1197, "lng": 72.8464},
    {"stop_id": 5, "name": "Dadar Station",      "lat": 19.0178, "lng": 72.8478}
  ]'
) ON CONFLICT DO NOTHING;

-- Pre-seed Bus 330 (on route 1, starting at Dadar)
INSERT INTO buses (bus_number, route_id, current_lat, current_lng, crowd_level)
VALUES ('MH-330-5501', 1, 19.0178, 72.8478, 'empty')
ON CONFLICT DO NOTHING;

-- Pre-seed Bus 451 (on route 2, starting at Borivali)  
INSERT INTO buses (bus_number, route_id, current_lat, current_lng, crowd_level)
VALUES ('MH-451-7702', 2, 19.2295, 72.8568, 'moderate')
ON CONFLICT DO NOTHING;

-- Seed conductor: Conductor Raj (phone: 9876543210, password: conductor123)
-- bcrypt hash of 'conductor123' with 10 rounds
INSERT INTO users (name, phone, role, bus_id, route_id, password_hash, xp) VALUES (
  'Conductor Raj',
  '9876543210',
  'conductor',
  1,
  1,
  '$2a$10$BuSSrCskNoICIj4cJ.WRMO/Ooa0iC2RjOncWsWtBL8C1WADoH.ZEO',
  120
) ON CONFLICT (phone) DO NOTHING;

-- Seed passenger: Passenger Anil (phone: 9988776655, password: passenger123)  
INSERT INTO users (name, phone, role, password_hash, xp) VALUES (
  'Passenger Anil',
  '9988776655',
  'passenger',
  '$2a$10$k3NXDOnAmgDlJbAcj.88jeCRfNU91xutGQB4iRjmVSJvsi7F3fTli',
  50
) ON CONFLICT (phone) DO NOTHING;