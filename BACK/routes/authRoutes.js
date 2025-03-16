// routes/authRoutes.js
const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/AuthController');  // Make sure the controller is imported
const { verifyToken, checkRole } = require('../middlewares/AuthMiddleware');
const { validateRegisterInput } = require('../middlewares/ValidationMiddleware');

// Register route with validation middleware
router.post('/register', AuthController.registerUser); // Ensure the controller method exists

// Login route
router.post('/login', AuthController.loginUser);  // Ensure the controller method exists

// Protected routes
//router.get('/doctors', verifyToken, checkRole(['patient', 'admin']), AuthController.getAllDoctors);  // Ensure the controller method exists
//router.put('/approve-doctor/:id', verifyToken, checkRole(['admin']), AuthController.approveDoctor); // Ensure the controller method exists

module.exports = router;
