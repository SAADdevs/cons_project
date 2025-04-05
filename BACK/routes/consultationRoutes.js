const express = require('express');
const { requestConsultation, getDoctorConsultations, updateConsultationStatus } = require('../controllers/ConsultationController');
const router = express.Router();

router.post('/request', requestConsultation);
router.get('/doctor/:doctor_id', getDoctorConsultations);
router.put('/update-status', updateConsultationStatus);
 
module.exports = router;
