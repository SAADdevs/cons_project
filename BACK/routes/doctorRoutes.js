const express = require('express');
const router = express.Router();
const DoctorController = require('../controllers/DoctorController'); 

// Basic routes for doctors
router.get('/doctors', DoctorController.getAllDoctors);
router.get('/doctors/verified', DoctorController.getVerifiedDoctors); 
router.get('/doctors/specialty/:specialty', DoctorController.getDoctorsBySpecialty); 
router.get('/doctors/:id', DoctorController.getDoctorById); 

// Admin routes for doctor verification
router.put('/doctors/approve/:id', DoctorController.approveDoctor);
router.put('/doctors/unverify/:id', DoctorController.unverifyDoctor);

// Doctor availability route
router.put('/doctors/update-availability', DoctorController.updateDoctorAvailability);

// Route for getting doctors with names - crucial for the frontend
router.get('/doctors/with-names', DoctorController.getDoctorsWithNames);
router.get('/doctors/available/list', DoctorController.getAvailableDoctors);

module.exports = router;