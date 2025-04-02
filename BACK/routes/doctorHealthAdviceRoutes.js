// routes/doctorHealthAdviceRoutes.js
const express = require('express');
const router = express.Router();
const DoctorHealthAdviceController = require('../controllers/DoctorHealthAdviceController');
const { verifyToken, checkRole } = require('../middlewares/AuthMiddleware');

// Public routes
// Get all approved health advice
router.get('/approved', DoctorHealthAdviceController.getAllApprovedAdvice);

// Get approved health advice by category
router.get('/category/:category', DoctorHealthAdviceController.getApprovedAdviceByCategory);

// Get specific health advice (if approved, or if doctor is the author)
router.get('/:id', DoctorHealthAdviceController.getAdviceById);

// Protected routes (require authentication)
// Create new health advice (doctor only)
router.post('/create', verifyToken, checkRole(['doctor']), DoctorHealthAdviceController.createAdvice);

// Get all health advice for a doctor
// Note: When accessed by admin, shows all the doctor's advice
// When accessed by the doctor, shows their own advice
// When accessed by another doctor, shows only approved advice
router.get('/doctor/:doctor_id', verifyToken, DoctorHealthAdviceController.getAdviceByDoctor);

// Update health advice (doctor can only update their own)
router.put('/:id', verifyToken, checkRole(['doctor', 'admin']), DoctorHealthAdviceController.updateAdvice);

// Delete health advice (doctor can only delete their own)
router.delete('/:id', verifyToken, checkRole(['doctor', 'admin']), DoctorHealthAdviceController.deleteAdvice);

// Admin routes
// Approve health advice
router.put('/approve/:id', verifyToken, checkRole(['admin']), DoctorHealthAdviceController.approveAdvice);

// Get all pending advice
router.get('/admin/pending', verifyToken, checkRole(['admin']), DoctorHealthAdviceController.getPendingAdvice);

module.exports = router;