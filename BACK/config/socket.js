// config/socket.js
const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const ChatMessage = require('../Models/ChatMessage');
const Consultation = require('../Models/Consultation');
const User = require('../Models/User');

const setupSocket = (server) => {
  const io = socketIo(server, {
    cors: {
      origin: process.env.CLIENT_URL || "*",
      methods: ["GET", "POST"],
      credentials: true
    }
  });

  // Authentication middleware for socket connections
  io.use(async (socket, next) => {
    try {
      // Extract token from socket handshake
      const token = socket.handshake.auth.token;
      
      if (!token) {
        return next(new Error("Authentication token required"));
      }
      
      // Verify JWT token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // Store user info in socket for later use
      socket.user = {
        id: decoded.id,
        role: decoded.role
      };
      
      next();
    } catch (error) {
      console.error("Socket authentication error:", error);
      next(new Error("Authentication failed"));
    }
  });

  // Connection event
  io.on('connection', (socket) => {
    console.log(`User connected: ${socket.user.id}`);
    
    // Join user's personal room for direct notifications
    socket.join(`user_${socket.user.id}`);
    
    // Send a message
    socket.on('send_message', async (data) => {
      try {
        const { 
          consultation_id, 
          receiver_id, 
          message_text, 
          media_url, 
          message_type 
        } = data;
        
        // Validate required fields
        if (!consultation_id || !receiver_id || !message_text) {
          throw new Error('Missing required message fields');
        }
        
        // Create message in database
        const newMessage = await ChatMessage.createMessage(
          socket.user.id,   // sender_id
          receiver_id,       // receiver_id
          consultation_id,   // consultation_id
          message_text,      // message_text
          media_url,         // media_url (optional)
          message_type       // message_type
        );
        
        // Get sender's name
        const sender = await User.getUserById(socket.user.id);
        
        // Add sender name to message
        newMessage.sender_name = sender.full_name;
        
        // Emit to consultation room
        io.to(`consultation_${consultation_id}`).emit('new_message', newMessage);
        
        // Emit personal notification to receiver
        io.to(`user_${receiver_id}`).emit('notification', {
          type: 'new_message',
          message: newMessage
        });
      } catch (error) {
        console.error('Error sending message:', error);
        socket.emit('error', { 
          message: 'Failed to send message', 
          details: error.message 
        });
      }
    });

    // Join consultation room
    socket.on('join_consultation', async (consultationId) => {
      try {
        // Verify consultation exists and user is a participant
        const consultation = await Consultation.getById(consultationId);
        
        if (!consultation) {
          return socket.emit('error', { message: "Consultation not found" });
        }
        
        // Check if user is a participant
        const isParticipant = 
          consultation.patient_id === socket.user.id || 
          consultation.doctor_id === socket.user.id;
        
        if (!isParticipant) {
          return socket.emit('error', { message: "Not authorized to join this consultation" });
        }
        
        // Join the consultation room
        socket.join(`consultation_${consultationId}`);
        
        // Mark messages as read
        await ChatMessage.markAsRead(socket.user.id, consultationId);
      } catch (error) {
        console.error('Error joining consultation:', error);
        socket.emit('error', { message: "Failed to join consultation" });
      }
    });

    // Typing indicators
    socket.on('typing', (data) => {
      const { consultation_id } = data;
      
      // Broadcast typing to others in consultation room
      socket.to(`consultation_${consultation_id}`).emit('user_typing', {
        user_id: socket.user.id,
        consultation_id
      });
    });

    socket.on('stop_typing', (data) => {
      const { consultation_id } = data;
      
      socket.to(`consultation_${consultation_id}`).emit('user_stop_typing', {
        user_id: socket.user.id,
        consultation_id
      });
    });

    // Mark messages as read
    socket.on('mark_read', async (data) => {
      try {
        const { consultation_id } = data;
        
        // Mark messages as read
        const updatedMessages = await ChatMessage.markAsRead(
          socket.user.id, 
          consultation_id
        );
        
        // Notify other participants
        socket.to(`consultation_${consultation_id}`).emit('messages_read', {
          consultation_id,
          user_id: socket.user.id,
          count: updatedMessages.length
        });
      } catch (error) {
        console.error('Error marking messages as read:', error);
        socket.emit('error', { message: "Failed to mark messages as read" });
      }
    });

    // Disconnect event
    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.user.id}`);
    });
  });

  return io;
};

module.exports = setupSocket;