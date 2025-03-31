// routes/patientRoutes.js
const express = require('express');
const router = express.Router();
const PatientController = require('../controllers/PatientController');

// Public routes - doctors listing
router.get('/doctors', PatientController.getAvailableDoctors);
router.get('/doctors/specialty/:specialty', PatientController.getDoctorsBySpecialty);
router.get('/doctors/:id', PatientController.getDoctorById);

// Consultation routes
router.post('/consultations/request', PatientController.requestConsultation);
router.get('/consultations/:patient_id', PatientController.getPatientConsultations);
router.get('/consultations/details/:id', PatientController.getConsultationDetails);

// Get health advice for patients
router.get('/health-advice', PatientController.getApprovedHealthAdvice);
router.get('/health-advice/:id', PatientController.getHealthAdviceById);
router.get('/health-advice/category/:category', PatientController.getHealthAdviceByCategory);

// Patient profile
router.get('/profile/:patient_id', PatientController.getPatientProfile);
router.put('/profile/:patient_id', PatientController.updatePatientProfile);

router.get('/consultations/:patient_id', PatientController.getPatientConsultations);
router.get('/consultations/get-patient-id/:user_id', PatientController.getPatientIdByUserId);




module.exports = router;