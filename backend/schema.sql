CREATE TYPE crowd_level_enum AS ENUM ('empty', 'moderate', 'full', 'overcrowded');
CREATE TYPE user_role_enum AS ENUM ('conductor', 'passenger');

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

-- Seed route
INSERT INTO routes (route_number, route_name, stops) VALUES (
  '21C',
  'Adyar to T. Nagar',
  '[
    {"stop_id": 1, "name": "Adyar Signal",      "lat": 13.0012, "lng": 80.2565},
    {"stop_id": 2, "name": "Kotturpuram",        "lat": 13.0137, "lng": 80.2456},
    {"stop_id": 3, "name": "Saidapet",           "lat": 13.0196, "lng": 80.2213},
    {"stop_id": 4, "name": "T. Nagar Bus Stand", "lat": 13.0358, "lng": 80.2338}
  ]'
) ON CONFLICT DO NOTHING;

-- Seed bus
INSERT INTO buses (bus_number, route_id, current_lat, current_lng, crowd_level)
VALUES ('BUS-21C-01', 1, 13.0012, 80.2565, 'empty')
ON CONFLICT DO NOTHING;