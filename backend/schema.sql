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
  rank TEXT DEFAULT 'Rookie Reporter',
  streak_days INTEGER DEFAULT 0,
  last_update_date DATE,
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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_buses_route_id ON buses(route_id);
CREATE INDEX IF NOT EXISTS idx_buses_conductor_id ON buses(conductor_id);
CREATE INDEX IF NOT EXISTS idx_crowd_logs_bus_id ON crowd_logs(bus_id);
CREATE INDEX IF NOT EXISTS idx_crowd_logs_conductor_id ON crowd_logs(conductor_id);

-- ===== SEED DATA: Chennai Route 21C (Adyar to T. Nagar) =====

-- Route 1: Adyar to T. Nagar (Chennai)
INSERT INTO routes (route_number, route_name, stops) VALUES (
  '21C',
  'Adyar to T. Nagar',
  '[
    {"stop_id": 1, "name": "Adyar Signal",  "lat": 13.0067, "lng": 80.2206},
    {"stop_id": 2, "name": "Kotturpuram",   "lat": 13.0142, "lng": 80.2263},
    {"stop_id": 3, "name": "Saidapet",      "lat": 13.0201, "lng": 80.2237},
    {"stop_id": 4, "name": "T. Nagar",      "lat": 13.0418, "lng": 80.2341}
  ]'
) ON CONFLICT DO NOTHING;

-- Seed Conductor Raj (phone: 9876543210, password: conductor123)
-- bcrypt hash of 'conductor123' with 10 rounds
INSERT INTO users (name, phone, role, bus_id, route_id, password_hash, xp, rank) VALUES (
  'Conductor Raj',
  '9876543210',
  'conductor',
  1,
  1,
  '$2a$10$BuSSrCskNoICIj4cJ.WRMO/Ooa0iC2RjOncWsWtBL8C1WADoH.ZEO',
  120,
  'Rookie Reporter'
) ON CONFLICT (phone) DO NOTHING;

-- Seed Passenger Anil (phone: 9988776655, password: passenger123)
INSERT INTO users (name, phone, role, password_hash, xp) VALUES (
  'Passenger Anil',
  '9988776655',
  'passenger',
  '$2a$10$k3NXDOnAmgDlJbAcj.88jeCRfNU91xutGQB4iRjmVSJvsi7F3fTli',
  0
) ON CONFLICT (phone) DO NOTHING;

-- Bus 21C-001: starts at Adyar Signal (first stop), assigned to Conductor Raj
INSERT INTO buses (bus_number, route_id, conductor_id, current_lat, current_lng, crowd_level)
VALUES ('21C-001', 1, 1, 13.0067, 80.2206, 'empty')
ON CONFLICT DO NOTHING;

-- Bus 21C-002: starts near Saidapet (third stop), no conductor assigned
INSERT INTO buses (bus_number, route_id, current_lat, current_lng, crowd_level)
VALUES ('21C-002', 1, 13.0201, 80.2237, 'empty')
ON CONFLICT DO NOTHING;