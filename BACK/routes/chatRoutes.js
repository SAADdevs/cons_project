// routes/chatRoutes.js
const express = require('express');
const router = express.Router();
const ChatController = require('../controllers/ChatController');

// Send a new message
router.post('/send', ChatController.sendMessage);

// Get chat history for a consultation
router.get('/consultation/:consultation_id', ChatController.getConsultationChat);

// Get unread message count for a user
router.get('/unread/:user_id', ChatController.getUnreadCount);

// Mark messages as read
router.put('/mark-read', ChatController.markMessagesAsRead);

module.exports = router;