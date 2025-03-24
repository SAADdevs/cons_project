// routes/healthAdviceRoutes.js
const express = require('express');
const router = express.Router();
const HealthAdviceController = require('../controllers/HealthAdviceController');

// Get all health advice (public route)
router.get('/', HealthAdviceController.getAllHealthAdvice);

// Get approved health advice (for patients) - MOVE THIS BEFORE /:id
router.get('/approved', HealthAdviceController.getApprovedHealthAdvice);

// Get health advice by category
router.get('/category/:category', HealthAdviceController.getHealthAdviceByCategory);

// Get health advice by doctor ID
router.get('/doctor/:doctorId', HealthAdviceController.getHealthAdviceByDoctor);

// Get health advice by ID - THIS SHOULD COME AFTER OTHER SPECIFIC ROUTES
router.get('/:id', HealthAdviceController.getHealthAdviceById);

// Post new health advice
router.post('/create', HealthAdviceController.createHealthAdvice);

// Update existing health advice
router.put('/:id', HealthAdviceController.updateHealthAdvice);

// Delete health advice
router.delete('/:id', HealthAdviceController.deleteHealthAdvice);

// Admin: Approve health advice
router.put('/approve/:id', HealthAdviceController.approveHealthAdvice);

module.exports = router;