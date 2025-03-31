// config/socket.js
const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../Models/User');
const ChatMessage = require('../models/ChatMessage');
const Consultation = require('../Models/Consultation');

// Setup socket.io with authentication and event handling
const setupSocket = (server) => {
    const io = socketIo(server, {
        cors: {
            origin: process.env.CLIENT_URL || "*",
            methods: ["GET", "POST"],
            credentials: true
        }
    });
    
    // Middleware for authentication
    io.use(async (socket, next) => {
        try {
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
    
    // Handle connection
    io.on('connection', (socket) => {
        console.log(`User connected: ${socket.user.id}`);
        
        // Join personal room for direct messages
        socket.join(`user_${socket.user.id}`);
        
        // Handle joining a consultation room
        socket.on('join_consultation', async (consultationId) => {
            try {
                // Verify the user is part of this consultation
                const consultation = await Consultation.getById(consultationId);
                
                if (!consultation) {
                    socket.emit('error', { message: "Consultation not found" });
                    return;
                }
                
                const isParticipant = 
                    consultation.patient_id == socket.user.id || 
                    consultation.doctor_id == socket.user.id;
                
                if (!isParticipant) {
                    socket.emit('error', { message: "Not authorized to join this consultation" });
                    return;
                }
                
                // Join the consultation room
                socket.join(`consultation_${consultationId}`);
                
                // Notify the other participant that user is online
                const otherUserId = consultation.patient_id == socket.user.id 
                    ? consultation.doctor_id 
                    : consultation.patient_id;
                
                io.to(`user_${otherUserId}`).emit('user_online', {
                    consultation_id: consultationId,
                    user_id: socket.user.id
                });
                
                // Mark messages as read when joining
                await ChatMessage.markAsRead(socket.user.id, consultationId);
                
                // Emit to the other user that messages have been read
                io.to(`user_${otherUserId}`).emit('messages_read', {
                    consultation_id: consultationId,
                    user_id: socket.user.id
                });
                
                console.log(`User ${socket.user.id} joined consultation ${consultationId}`);
            } catch (error) {
                console.error("Error joining consultation:", error);
                socket.emit('error', { message: "Server error joining consultation" });
            }
        });
        
        // Handle leaving a consultation
        socket.on('leave_consultation', (consultationId) => {
            socket.leave(`consultation_${consultationId}`);
            console.log(`User ${socket.user.id} left consultation ${consultationId}`);
        });
        
        // Handle new message
        socket.on('send_message', async (messageData) => {
            try {
                const { consultation_id, receiver_id, message_text, media_url, message_type } = messageData;
                
                // Create the message in database
                const newMessage = await ChatMessage.createMessage(
                    socket.user.id, // sender_id from authenticated socket
                    receiver_id,
                    consultation_id,
                    message_text,
                    media_url,
                    message_type
                );
                
                // Get sender info
                const sender = await User.getUserById(socket.user.id);
                
                // Add sender name to the message
                newMessage.sender_name = sender.full_name;
                
                // Emit to the consultation room
                io.to(`consultation_${consultation_id}`).emit('new_message', newMessage);
                
                // Also emit to the receiver's personal room (for notifications)
                io.to(`user_${receiver_id}`).emit('notification', {
                    type: 'new_message',
                    message: newMessage
                });
                
                console.log(`Message sent from ${socket.user.id} to ${receiver_id} in consultation ${consultation_id}`);
            } catch (error) {
                console.error("Error sending message:", error);
                socket.emit('error', { message: "Failed to send message" });
            }
        });
        
        // Handle typing indicator
        socket.on('typing', (data) => {
            const { consultation_id } = data;
            
            // Broadcast to others in the consultation room that this user is typing
            socket.to(`consultation_${consultation_id}`).emit('user_typing', {
                user_id: socket.user.id,
                consultation_id
            });
        });
        
        // Handle stop typing indicator
        socket.on('stop_typing', (data) => {
            const { consultation_id } = data;
            
            socket.to(`consultation_${consultation_id}`).emit('user_stop_typing', {
                user_id: socket.user.id,
                consultation_id
            });
        });
        
        // Handle marking messages as read
        socket.on('mark_read', async (data) => {
            try {
                const { consultation_id } = data;
                
                // Mark messages as read
                const updatedMessages = await ChatMessage.markAsRead(socket.user.id, consultation_id);
                
                // Get the consultation to find the other participant
                const consultation = await Consultation.getById(consultation_id);
                
                if (consultation) {
                    const otherUserId = consultation.patient_id == socket.user.id 
                        ? consultation.doctor_id 
                        : consultation.patient_id;
                    
                    // Emit read receipt to the other participant
                    io.to(`user_${otherUserId}`).emit('messages_read', {
                        consultation_id,
                        user_id: socket.user.id,
                        count: updatedMessages.length
                    });
                }
            } catch (error) {
                console.error("Error marking messages as read:", error);
                socket.emit('error', { message: "Failed to mark messages as read" });
            }
        });
        
        // Handle disconnect
        socket.on('disconnect', () => {
            console.log(`User disconnected: ${socket.user.id}`);
            
            // You can also emit a user_offline event to relevant users here
        });
    });
    
    return io;
};

module.exports = setupSocket;