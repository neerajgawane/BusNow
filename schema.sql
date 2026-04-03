CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  phone VARCHAR(15) UNIQUE,
  role VARCHAR(20) CHECK (role IN ('conductor', 'passenger')),
  bus_id INTEGER,
  route_id INTEGER,
  password_hash TEXT,
  xp INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS routes (
  id SERIAL PRIMARY KEY,
  route_number VARCHAR(20),
  route_name VARCHAR(100),
  stops JSONB
);

CREATE TABLE IF NOT EXISTS buses (
  id SERIAL PRIMARY KEY,
  bus_number VARCHAR(20),
  route_id INTEGER REFERENCES routes(id),
  conductor_id INTEGER REFERENCES users(id),
  current_lat DOUBLE PRECISION,
  current_lng DOUBLE PRECISION,
  crowd_level VARCHAR(20) CHECK (crowd_level IN ('empty','moderate','full','overcrowded')),
  last_updated TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS crowd_logs (
  id SERIAL PRIMARY KEY,
  bus_id INTEGER REFERENCES buses(id),
  conductor_id INTEGER REFERENCES users(id),
  crowd_level VARCHAR(20),
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  timestamp TIMESTAMP DEFAULT NOW()
);

-- Seed Data

-- 1 route
INSERT INTO routes (route_number, route_name, stops) VALUES (
  '21C', 'Adyar to T. Nagar', 
  '[
    {"stop_id":1, "name":"Adyar Signal", "lat":13.0067, "lng":80.2206},
    {"stop_id":2, "name":"Kotturpuram", "lat":13.0142, "lng":80.2263},
    {"stop_id":3, "name":"Saidapet", "lat":13.0201, "lng":80.2237},
    {"stop_id":4, "name":"T. Nagar", "lat":13.0418, "lng":80.2341}
  ]'::jsonb
);

-- 1 conductor user
INSERT INTO users (name, phone, role, bus_id, route_id, password_hash)
VALUES (
  'Conductor Raj', 
  '9876543210', 
  'conductor', 
  1, 
  1, 
  crypt('BusNow@Conductor1', gen_salt('bf'))
);

-- 1 bus
INSERT INTO buses (bus_number, route_id, conductor_id, current_lat, current_lng, crowd_level)
VALUES ('21C-001', 1, 1, 13.0067, 80.2206, 'empty');
