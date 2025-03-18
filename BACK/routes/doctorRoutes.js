const express = require('express');
const router = express.Router();
const DoctorController = require('../controllers/DoctorController'); 

router.get('/doctors', DoctorController.getAllDoctors);

router.get("/doctors/verified", DoctorController.getVerifiedDoctors); 
router.get("/doctors/specialty/:specialty", DoctorController.getDoctorsBySpecialty); 
router.get("/doctors/:id", DoctorController.getDoctorById); 

router.put('/doctors/approve/:id', DoctorController.approveDoctor);
router.put('/doctors/unverify/:id', DoctorController.unverifyDoctor);
router.put('/doctors/update-availability', DoctorController.updateDoctorAvailability);
// Add the /doctors prefix to the with-names route
router.get('/with-names', DoctorController.getDoctorsWithNames);
router.get('/doctors/available/list', DoctorController.getAvailableDoctors);

module.exports = router;
