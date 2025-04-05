const express = require('express');
const router = express.Router();
const ChatController = require('../controllers/ChatController');
const { verifyToken } = require('../middlewares/AuthMiddleware');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const multer = require('multer');





const storage = multer.diskStorage({
    destination: (req, file, cb) => {
      const consultationId = req.body.consultation_id || 'default';
      const uploadPath = path.join(__dirname, '..', 'uploads', 'consultations', consultationId);
      
      // Ensure directory exists
      require('fs').mkdirSync(uploadPath, { recursive: true });
      cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
      const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1E9)}`;
      const extension = path.extname(file.originalname);
      cb(null, `${file.fieldname}-${uniqueSuffix}${extension}`);
    }
  });
const fileFilter = (req, file, cb) => {
    const allowedTypes = [
      // Images
      'image/jpeg', 'image/png', 'image/gif', 'image/bmp', 'image/webp',
      
      // Documents
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain'
    ];
  
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'), false);
    }
  };
  
  const upload = multer({ 
    storage: storage,
    fileFilter: fileFilter,
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB file size limit
  });
  

// Apply auth middleware to all chat routes
router.use(verifyToken);
router.post('/upload', upload.single('file'), ChatController.uploadMedia);

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