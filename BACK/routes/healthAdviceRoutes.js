// routes/healthAdviceRoutes.js
const express = require('express');
const router = express.Router();
const HealthAdviceController = require('../controllers/HealthAdviceController');

// Get all health advice (public route)
router.get('/', HealthAdviceController.getAllHealthAdvice);

// Get health advice by ID
router.get('/:id', HealthAdviceController.getHealthAdviceById);

// Post new health advice
router.post('/create', HealthAdviceController.createHealthAdvice);

// Update existing health advice
router.put('/:id', HealthAdviceController.updateHealthAdvice);

// Delete health advice
router.delete('/:id', HealthAdviceController.deleteHealthAdvice);

// Get health advice by category
router.get('/category/:category', HealthAdviceController.getHealthAdviceByCategory);

// Get health advice by doctor ID
router.get('/doctor/:doctorId', HealthAdviceController.getHealthAdviceByDoctor);

// Get approved health advice (for patients)
router.get('/approved', HealthAdviceController.getApprovedHealthAdvice);

// Admin: Approve health advice
router.put('/approve/:id', HealthAdviceController.approveHealthAdvice);

module.exports = router;