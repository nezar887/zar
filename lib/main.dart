// خادم الإشارة (Signaling) + منطق غرفة الانتظار
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server);
app.use(express.static('public'));

// roomId -> { host, members: Map(socketId -> name), waiting: Map(socketId -> name) }
const rooms = new Map();
const newId = () => Math.random().toString(36).slice(2, 8).toUpperCase();
const clean = (s, d) => String(s || d).trim().slice(0, 30) || d;

io.on('connection', (socket) => {
  const myRoom = () => rooms.get(socket.data.roomId);
  const pushWaiting = (room) =>
    io.to(room.host).emit('waiting-list', [...room.waiting].map(([id, name]) => ({ id, name })));

  // المضيف ينشئ غرفة
  socket.on('create-room', (name) => {
    let id;
    do { id = newId(); } while (rooms.has(id));
    name = clean(name, 'المضيف');
    rooms.set(id, { host: socket.id, members: new Map([[socket.id, name]]), waiting: new Map() });
    socket.data = { roomId: id, name };
    socket.join(id);
    socket.emit('room-created', { roomId: id });
  });

  // ضيف يطلب الدخول → يدخل غرفة الانتظار
  socket.on('join-request', ({ roomId, name }) => {
    roomId = String(roomId || '').trim().toUpperCase();