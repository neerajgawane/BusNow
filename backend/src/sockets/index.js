module.exports = (io) => {
  io.on('connection', (socket) => {
    console.log(`🔌 Client connected: ${socket.id}`);

    socket.on('stop:subscribe', ({ stop_id }) => {
      socket.join(`stop:${stop_id}`);
      console.log(`📍 Socket ${socket.id} subscribed to stop:${stop_id}`);
    });

    socket.on('bus:join', ({ bus_id }) => {
      socket.join(`bus:${bus_id}`);
      console.log(`🚌 Socket ${socket.id} joined bus:${bus_id}`);
    });

    socket.on('disconnect', () => {
      console.log(`❌ Client disconnected: ${socket.id}`);
    });
  });
};