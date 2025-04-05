// routes/authRoutes.js
const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/AuthController');  // Make sure the controller is imported
const { verifyToken, checkRole } = require('../middlewares/AuthMiddleware');
const { validateRegisterInput } = require('../middlewares/ValidationMiddleware');

// Register route with validation middleware
router.post('/register', AuthController.registerUser); // Ensure the controller method exists

// Login route
router.post('/login', AuthController.loginUser);

// Get authenticated user ID
router.post('/login/auth-user-id', AuthController.getAuthUserId);

// User profile routes
router.get('/profile', verifyToken, AuthController.getUserProfile);
router.put('/profile', verifyToken, AuthController.updateUserProfile); // NEW: Add route for updating user profile

// Password management
router.post('/change-password', verifyToken, AuthController.changePassword);
router.get('/me', verifyToken,
    AuthController.getCurrentUser
);


module.exports = router;