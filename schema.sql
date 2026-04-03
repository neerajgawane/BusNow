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
  rank TEXT DEFAULT 'Rookie Reporter',
  streak_days INTEGER DEFAULT 0,
  last_update_date DATE,
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

-- Seed Data (Hubli-Dharwad BRTS Route)
INSERT INTO routes (route_number, route_name, stops) VALUES (
  'BRTS', 'Dharwad to Hubli',
  '[
    {"stop_id":1,  "name":"Dharwad New Bus Stand",       "lat":15.4589, "lng":75.0078},
    {"stop_id":2,  "name":"Dharwad BRTS Terminal",       "lat":15.4560, "lng":75.0095},
    {"stop_id":3,  "name":"Jubilee Circle",              "lat":15.4530, "lng":75.0110},
    {"stop_id":4,  "name":"Court Circle",                "lat":15.4498, "lng":75.0118},
    {"stop_id":5,  "name":"NTTF",                        "lat":15.4470, "lng":75.0130},
    {"stop_id":6,  "name":"Hosayellapur Cross",          "lat":15.4440, "lng":75.0155},
    {"stop_id":7,  "name":"Toll Naka",                   "lat":15.4410, "lng":75.0175},
    {"stop_id":8,  "name":"Vidyagiri",                   "lat":15.4375, "lng":75.0200},
    {"stop_id":9,  "name":"Gandhinagar",                 "lat":15.4345, "lng":75.0225},
    {"stop_id":10, "name":"Yelakki Shelter Colony Cross", "lat":15.4310, "lng":75.0255},
    {"stop_id":11, "name":"Lakamanahalli",               "lat":15.4275, "lng":75.0280},
    {"stop_id":12, "name":"Navalur",                     "lat":15.4240, "lng":75.0310},
    {"stop_id":13, "name":"Sattur",                      "lat":15.4205, "lng":75.0340},
    {"stop_id":14, "name":"SDM Medical College",         "lat":15.4170, "lng":75.0370},
    {"stop_id":15, "name":"Navalur Railway Station",     "lat":15.4135, "lng":75.0400},
    {"stop_id":16, "name":"Sanjivini Park",              "lat":15.4100, "lng":75.0430},
    {"stop_id":17, "name":"KMF1",                        "lat":15.4060, "lng":75.0460},
    {"stop_id":18, "name":"Iskcon Temple",               "lat":15.4020, "lng":75.0490},
    {"stop_id":19, "name":"RTO Office",                  "lat":15.3980, "lng":75.0520},
    {"stop_id":20, "name":"Rayapur",                     "lat":15.3940, "lng":75.0555},
    {"stop_id":21, "name":"Navanagar",                   "lat":15.3900, "lng":75.0590},
    {"stop_id":22, "name":"APMC 3rd Gate",               "lat":15.3860, "lng":75.0625},
    {"stop_id":23, "name":"Shantiniketan",               "lat":15.3820, "lng":75.0660},
    {"stop_id":24, "name":"Bairidevarkoppa",             "lat":15.3780, "lng":75.0700},
    {"stop_id":25, "name":"Unkal Lake",                  "lat":15.3740, "lng":75.0740},
    {"stop_id":26, "name":"Unakal",                      "lat":15.3700, "lng":75.0775},
    {"stop_id":27, "name":"Unakal Cross",                "lat":15.3665, "lng":75.0810},
    {"stop_id":28, "name":"BVB",                         "lat":15.3630, "lng":75.0845},
    {"stop_id":29, "name":"Vidyanagar",                  "lat":15.3595, "lng":75.0880},
    {"stop_id":30, "name":"KIMS",                        "lat":15.3560, "lng":75.0915},
    {"stop_id":31, "name":"Hosur Regional Terminal",     "lat":15.3525, "lng":75.0950},
    {"stop_id":32, "name":"Hosur Cross",                 "lat":15.3490, "lng":75.0985},
    {"stop_id":33, "name":"Hubli Central",               "lat":15.3455, "lng":75.1020},
    {"stop_id":34, "name":"Dr. B R Ambedkar Railway Station", "lat":15.3420, "lng":75.1055},
    {"stop_id":35, "name":"HDMC",                        "lat":15.3385, "lng":75.1090},
    {"stop_id":36, "name":"Hubli CBT",                   "lat":15.3350, "lng":75.1124}
  ]'::jsonb
);

INSERT INTO users (name, phone, role, bus_id, route_id, password_hash)
VALUES (
  'Conductor Raj',
  '9876543210',
  'conductor',
  1,
  1,
  crypt('conductor123', gen_salt('bf'))
);

INSERT INTO users (name, phone, role, password_hash)
VALUES (
  'Passenger Anil',
  '9988776655',
  'passenger',
  crypt('passenger123', gen_salt('bf'))
);

INSERT INTO buses (bus_number, route_id, conductor_id, current_lat, current_lng, crowd_level)
VALUES ('BRTS-001', 1, 1, 15.4589, 75.0078, 'empty');

INSERT INTO buses (bus_number, route_id, current_lat, current_lng, crowd_level)
VALUES ('BRTS-002', 1, 15.3980, 75.0520, 'empty');
