require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const busRoutes = require('./routes/buses');
const routeRoutes = require('./routes/routes');
const stopRoutes = require('./routes/stops');
const setupSockets = require('./sockets');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/buses', busRoutes(io));
app.use('/api/routes', routeRoutes);
app.use('/api/stops', stopRoutes);

// Health check
app.get('/', (req, res) => res.json({ status: '🚌 BusNow API running' }));

setupSockets(io);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚌 BusNow backend running on http://localhost:${PORT}`);
});