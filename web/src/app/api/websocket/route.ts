import { Server } from 'socket.io';

const ioHandler = (req, res) => {
  if (!res.socket.server.io) {
    console.log('Starting socket.io server...');
    const io = new Server(res.socket.server);
    io.on('connection', (socket) => {
      socket.on('message', (msg) => {
        console.log(msg);
        socket.broadcast.emit('message', msg);
      });
    });
    res.socket.server.io = io;
  } else {
    console.log('Socket.io server already running');
  }
  res.end();
};

export default ioHandler;
