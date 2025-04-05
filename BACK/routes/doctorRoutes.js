const express = require('express');
const router = express.Router();
const DoctorController = require('../controllers/DoctorController'); 

// Basic routes for doctors
router.get('/', DoctorController.getAllDoctors);
router.get('/verified', DoctorController.getVerifiedDoctors); 
router.get('/specialty/:specialty', DoctorController.getDoctorsBySpecialty); 
router.get('/:id', DoctorController.getDoctorById); 

// Admin routes for doctor verification
router.put('/approve/:id', DoctorController.approveDoctor);
router.put('/unverify/:id', DoctorController.unverifyDoctor);

// Doctor availability route
router.put('/update-availability', DoctorController.updateDoctorAvailability);

// Route for getting doctors with names - crucial for the frontend
router.get('/get/with-names', DoctorController.getDoctorsWithNames);
router.get('/available/list', DoctorController.getAvailableDoctors);
router.get('/get-doctor-id/:user_id', DoctorController.getDoctorIdByUserId);

module.exports = router;