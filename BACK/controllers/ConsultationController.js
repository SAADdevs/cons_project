const Consultation = require('../Models/Consultation');
const pool = require('../config/db');
const Doctor = require('../Models/Doctor');  // Add this import

const requestConsultation = async (req, res) => {
  try {
    const { patient_id, doctor_id, is_emergency, type } = req.body;

    // Validate the type (optional but recommended)
    const validTypes = ["text", "voice", "video"];
    const consultationType = validTypes.includes(type) ? type : "text"; // Default to text if invalid

    // Create the consultation
    const newConsultation = await Consultation.createConsultation(
      patient_id, 
      doctor_id, 
      is_emergency, 
      consultationType // Pass the validated type
    );

    res.status(201).json(newConsultation);
  } catch (error) {
    console.error("Error in requestConsultation:", error.message);
    res.status(500).json({ error: "Internal server error", details: error.message });
  }
};

const getDoctorConsultations = async (req, res) => {
  try {
    // Log what's coming in to debug
    console.log('Request params:', req.params);
    
    // Get doctor_id from the URL parameter
    const doctorId = req.params.doctor_id;
    console.log('Doctor ID from params:', doctorId);
    
    if (!doctorId) {
      return res.status(400).json({ message: "Doctor ID is required" });
    }
    
    // Pass the doctorId to the model method
    const consultations = await Consultation.getDoctorConsultations(doctorId);
    console.log('Consultations found:', consultations.length);
    
    return res.json(consultations);
  } catch (error) {
    console.error('Error in getDoctorConsultations controller:', error);
    return res.status(500).json({ message: "Server error" });
  }
};

const updateConsultationStatus = async (req, res) => {
  try {
    const { consultation_id, status, consultation_date } = req.body;

    // Ensure status is valid
    const validStatuses = ["pending", "accepted", "rejected", "completed"];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: "Invalid status value" });
    }

    // If accepting, ensure date is provided
    if (status === "accepted" && !consultation_date) {
      return res.status(400).json({ message: "Consultation date is required when accepting a request." });
    }

    // Update consultation status
    const updatedConsultation = await Consultation.updateStatus(
      consultation_id, 
      status, 
      consultation_date
    );

    res.json({ message: "Consultation status updated", consultation: updatedConsultation });
  } catch (error) {
    console.error("Error updating consultation status:", error.message);
    res.status(500).json({ error: error.message });
  }
};

const getPatientsByDoctor = async (req, res) => {
  try {
    const userId = req.params.doctorId;
    
    console.log('Attempting to fetch patients for User ID:', userId);

    // First, get the doctor ID from the user ID
    const doctorResult = await pool.query(`
      SELECT id AS doctor_id 
      FROM doctors 
      WHERE user_id = $1
    `, [userId]);

    if (doctorResult.rows.length === 0) {
      return res.status(404).json({ 
        message: "Doctor not found for this user ID",
        details: { userId }
      });
    }

    const doctorId = doctorResult.rows[0].doctor_id;
    console.log('Converted User ID to Doctor ID:', doctorId);

    // Query to get patients who have consultations with this doctor
    const result = await pool.query(`
      SELECT DISTINCT
        p.id,
        u.full_name AS name,
        p.age,
        p.gender,
        (
          SELECT consultation_date 
          FROM consultations 
          WHERE patient_id = p.id AND doctor_id = $1 
          ORDER BY consultation_date DESC 
          LIMIT 1
        ) AS last_consultation_date,
        (
          SELECT COUNT(*) 
          FROM consultations 
          WHERE patient_id = p.id AND doctor_id = $1
        ) AS consultation_count,
        EXISTS (
          SELECT 1 
          FROM consultations 
          WHERE patient_id = p.id AND doctor_id = $1 AND status = 'pending'
        ) AS has_active_consultation
      FROM 
        consultations c
      JOIN 
        patients p ON c.patient_id = p.id
      JOIN 
        users u ON p.user_id = u.id
      WHERE 
        c.doctor_id = $1
      ORDER BY 
        last_consultation_date DESC
    `, [doctorId]);

    console.log(`Found ${result.rows.length} patients for doctor ID ${doctorId}`);

    // If no patients found, provide context
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        message: "No patients found for this doctor",
        details: {
          userId,
          doctorId
        }
      });
    }

    const patients = result.rows.map(patient => ({
      id: patient.id,
      name: patient.name,
      age: patient.age,
      gender: patient.gender,
      last_consultation_date: patient.last_consultation_date 
        ? new Date(patient.last_consultation_date).toISOString() 
        : null,
      consultation_count: patient.consultation_count.toString(),
      has_active_consultation: patient.has_active_consultation
    }));

    return res.json(patients);
  } catch (error) {
    console.error('Full error getting patients by doctor:', error);
    return res.status(500).json({ 
      message: "Server error", 
      error: error.message,
      stack: error.stack 
    });
  }
};
module.exports = {
  requestConsultation,
  getDoctorConsultations,
  updateConsultationStatus,
  getPatientsByDoctor
};