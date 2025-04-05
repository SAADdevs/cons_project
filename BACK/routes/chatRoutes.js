const express = require('express');
const router = express.Router();
const ChatController = require('../controllers/ChatController');
const { verifyToken } = require('../middlewares/AuthMiddleware');

// Apply auth middleware to all chat routes
router.use(verifyToken);

// Send a new message
router.post('/send', ChatController.sendMessage);

// Get chat history for a consultation (with optional pagination)
router.get('/consultation/:consultation_id', ChatController.getConsultationChat);

// Get paginated chat history for a consultation
router.get('/consultation/:consultation_id/paginated', ChatController.getPaginatedConsultationChat);

// Get unread message count for a user (all consultations)
router.get('/unread/:user_id', ChatController.getUnreadCount);

// Get unread message count for a user in a specific consultation
router.get('/unread/:user_id/:consultation_id', ChatController.getUnreadCountForConsultation);

// Mark messages as read
router.put('/mark-read', ChatController.markMessagesAsRead);

// Delete a message (sender only)
router.delete('/message/:message_id', ChatController.deleteMessage);

// Search messages
router.get('/search', ChatController.searchMessages);

// Export chat history for a consultation
router.get('/export/:consultation_id', ChatController.exportChatHistory);

router.get('/export/:consultation_id/:user_id', ChatController.exportChatHistory);
// Clear chat history for a consultation
router.delete('/clear/:consultation_id', ChatController.clearChatHistory);


module.exports = router;