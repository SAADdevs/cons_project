// routes/upcomingAppointmentRoutes.js
const express = require('express');
const router = express.Router();
const UpcomingAppointmentController = require('../controllers/UpcomingAppointmentsController');

// Get upcoming appointments for a specific doctor
router.get('/doctor/:doctor_id', UpcomingAppointmentController.getDoctorUpcomingAppointments);

// Count upcoming appointments for a specific doctor
router.get('/count/:doctor_id', UpcomingAppointmentController.countDoctorUpcomingAppointments);

// Cancel an appointment (using URL parameter format)
router.put('/cancel/:consultation_id', UpcomingAppointmentController.cancelAppointment);

module.exports = router;