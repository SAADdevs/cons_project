// controllers/PatientController.js
const pool = require('../config/db');

class PatientController {
    // Get all available doctors
    static async getAvailableDoctors(req, res) {
        try {
            // Query to get all available and verified doctors with their names
            const query = `
                SELECT d.id, d.user_id, d.specialties, d.hospital, u.full_name
                FROM doctors d
                JOIN users u ON d.user_id = u.id
                WHERE d.is_available = true AND d.is_verified = true
            `;
            
            const result = await pool.query(query);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "No available doctors found" });
            }
            
            res.status(200).json(result.rows);
        } catch (error) {
            console.error('Error getting available doctors:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get doctors by specialty
    static async getDoctorsBySpecialty(req, res) {
        const { specialty } = req.params; 
        try {
            const result = await pool.query(`
                SELECT 
                    d.id, 
                    d.user_id, 
                    u.full_name,  // Add this line to fetch full name
                    d.specialties, 
                    d.hospital,
                    d.is_verified, 
                    d.is_available
                FROM 
                    doctors d
                JOIN 
                    users u ON d.user_id = u.id  // Add join with users table
                WHERE 
                    d.specialties LIKE $1
            `, [`%${specialty}%`]);    
            
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "No doctors found with that specialty" });
            }
    
            res.status(200).json(result.rows);
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get doctor by ID
    static async getDoctorById(req, res) {
        try {
            const { id } = req.params;
            
            // Query to get doctor with details
            const query = `
                SELECT d.id, d.user_id, d.specialties, d.hospital, d.is_available, u.full_name, u.email
                FROM doctors d
                JOIN users u ON d.user_id = u.id
                WHERE d.id = $1 AND d.is_verified = true
            `;
            
            const result = await pool.query(query, [id]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "Doctor not found" });
            }
            
            res.status(200).json(result.rows[0]);
        } catch (error) {
            console.error('Error getting doctor by ID:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Request consultation
    static async requestConsultation(req, res) {
        try {
            const { patient_id, doctor_id, is_emergency, type } = req.body;
            
            // Validate required fields
            if (!patient_id || !doctor_id || !type) {
                return res.status(400).json({ message: "Missing required fields" });
            }
            
            // Validate if patient exists
            const patientResult = await pool.query(`
                SELECT p.id FROM patients p 
                WHERE p.id = $1
            `, [patient_id]);
            
            if (patientResult.rows.length === 0) {
                return res.status(404).json({ message: "Patient not found" });
            }
            
            // Validate if doctor exists and is available
            const doctorResult = await pool.query(`
                SELECT d.id FROM doctors d
                WHERE d.id = $1 AND d.is_available = true AND d.is_verified = true
            `, [doctor_id]);
            
            if (doctorResult.rows.length === 0) {
                return res.status(404).json({ message: "Doctor not found or not available" });
            }
            
            // Validate consultation type
            const validTypes = ["text", "voice", "video"];
            if (!validTypes.includes(type)) {
                return res.status(400).json({ message: "Invalid consultation type" });
            }
            
            // Create consultation
            const result = await pool.query(`
                INSERT INTO consultations (patient_id, doctor_id, consultation_date, status, is_emergency, type, created_at)
                VALUES ($1, $2, NOW(), 'pending', $3, $4, NOW())
                RETURNING *
            `, [patient_id, doctor_id, is_emergency || false, type]);
            
            res.status(201).json({
                message: "Consultation request sent successfully",
                consultation: result.rows[0]
            });
        } catch (error) {
            console.error('Error requesting consultation:', error);
            res.status(500).json({ message: "Server error", error: error.message });
        }
    }

    // Get patient's consultations
    static async getPatientConsultations(req, res) {
        try {
            const { user_id } = req.params;
            console.log("User ID:", user_id);
    
            // Fetch the patient ID from the patients table
            const patientResult = await pool.query(
                `SELECT id FROM patients WHERE user_id = $1`,
                [user_id]
            );
            
            // Check if patient exists
            if (patientResult.rows.length === 0) {
                return res.status(404).json({ message: "Patient not found" });
            }
            
            const patientId = patientResult.rows[0].id;
            console.log("Patient ID:", patientId);
            
            // Query to get patient's consultations with doctor information
            const query = `
                SELECT 
                    c.id AS consultation_id,
                    c.doctor_id,
                    c.status,
                    c.type,
                    c.is_emergency,
                    c.consultation_date,
                    c.created_at,
                    d.specialties,
                    u.full_name AS doctor_name
                FROM 
                    consultations c
                JOIN 
                    doctors d ON c.doctor_id = d.id
                JOIN
                    users u ON d.user_id = u.id
                WHERE 
                    c.patient_id = $1
                ORDER BY
                    c.created_at DESC
            `;
            
            const result = await pool.query(query, [patientId]);
            
            res.status(200).json(result.rows);
        } catch (error) {
            console.error('Error getting patient consultations:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get consultation details
    static async getConsultationDetails(req, res) {
        try {
            const { id } = req.params;
            
            // Query to get consultation details with doctor information
            const query = `
                SELECT 
                    c.id AS consultation_id,
                    c.patient_id,
                    c.doctor_id,
                    c.status,
                    c.type,
                    c.is_emergency,
                    c.consultation_date,
                    c.created_at,
                    d.specialties,
                    d.hospital,
                    u.full_name AS doctor_name,
                    u.email AS doctor_email
                FROM 
                    consultations c
                JOIN 
                    doctors d ON c.doctor_id = d.id
                JOIN
                    users u ON d.user_id = u.id
                WHERE 
                    c.id = $1
            `;
            
            const result = await pool.query(query, [id]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "Consultation not found" });
            }
            
            res.status(200).json(result.rows[0]);
        } catch (error) {
            console.error('Error getting consultation details:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get approved health advice
    static async getApprovedHealthAdvice(req, res) {
        try {
            // Query to get all approved health advice with doctor information
            const query = `
                SELECT 
                    ha.id,
                    ha.title,
                    ha.advice_text,
                    ha.category,
                    ha.created_at,
                    d.specialties,
                    u.full_name AS doctor_name
                FROM 
                    health_advice ha
                JOIN 
                    doctors d ON ha.doctor_id = d.id
                JOIN
                    users u ON d.user_id = u.id
                WHERE 
                    ha.is_approved = true
                ORDER BY
                    ha.created_at DESC
            `;
            
            const result = await pool.query(query);
            
            res.status(200).json(result.rows);
        } catch (error) {
            console.error('Error getting approved health advice:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get health advice by ID
    static async getHealthAdviceById(req, res) {
        try {
            const { id } = req.params;
            
            // Query to get health advice details with doctor information
            const query = `
                SELECT 
                    ha.id,
                    ha.title,
                    ha.advice_text,
                    ha.category,
                    ha.created_at,
                    d.specialties,
                    u.full_name AS doctor_name
                FROM 
                    health_advice ha
                JOIN 
                    doctors d ON ha.doctor_id = d.id
                JOIN
                    users u ON d.user_id = u.id
                WHERE 
                    ha.id = $1 AND ha.is_approved = true
            `;
            
            const result = await pool.query(query, [id]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "Health advice not found" });
            }
            
            res.status(200).json(result.rows[0]);
        } catch (error) {
            console.error('Error getting health advice by ID:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get health advice by category
    static async getHealthAdviceByCategory(req, res) {
        try {
            const { category } = req.params;
            
            // Query to get approved health advice by category with doctor info
            const query = `
                SELECT 
                    ha.id,
                    ha.title,
                    ha.advice_text,
                    ha.category,
                    ha.created_at,
                    d.specialties,
                    u.full_name AS doctor_name
                FROM 
                    health_advice ha
                JOIN 
                    doctors d ON ha.doctor_id = d.id
                JOIN
                    users u ON d.user_id = u.id
                WHERE 
                    ha.category ILIKE $1 AND ha.is_approved = true
                ORDER BY
                    ha.created_at DESC
            `;
            
            const result = await pool.query(query, [`%${category}%`]);
            
            res.status(200).json(result.rows);
        } catch (error) {
            console.error('Error getting health advice by category:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get patient profile
    static async getPatientProfile(req, res) {
        try {
            const { patient_id } = req.params;
            
            // Query to get patient profile
            const query = `
                SELECT 
                    p.id,
                    p.age,
                    p.gender,
                    u.id AS user_id,
                    u.full_name,
                    u.email,
                    u.created_at
                FROM 
                    patients p
                JOIN 
                    users u ON p.user_id = u.id
                WHERE 
                    p.id = $1
            `;
            
            const result = await pool.query(query, [patient_id]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "Patient not found" });
            }
            
            res.status(200).json(result.rows[0]);
        } catch (error) {
            console.error('Error getting patient profile:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Update patient profile
    static async updatePatientProfile(req, res) {
        try {
            const { patient_id } = req.params;
            const { age, gender } = req.body;
            
            // Validate if patient exists
            const patientResult = await pool.query(`
                SELECT p.id FROM patients p 
                WHERE p.id = $1
            `, [patient_id]);
            
            if (patientResult.rows.length === 0) {
                return res.status(404).json({ message: "Patient not found" });
            }
            
            // Update patient information
            const query = `
                UPDATE patients
                SET age = $1, gender = $2
                WHERE id = $3
                RETURNING *
            `;
            
            const result = await pool.query(query, [age, gender, patient_id]);
            
            res.status(200).json({
                message: "Patient profile updated successfully",
                patient: result.rows[0]
            });
        } catch (error) {
            console.error('Error updating patient profile:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

   // controllers/PatientController.js - Fixed version

static async getPatientConsultations(req, res) {
    try {
      const { patient_id } = req.params;
      
      // Query to get patient's consultations with doctor information
      // Fix: Changed "d.specialty" to "d.specialties"
      const query = `
          SELECT 
              c.id AS consultation_id,
              c.doctor_id,
              c.status,
              c.type,
              c.is_emergency,
              c.consultation_date,
              c.created_at,
              d.specialties,
              u.full_name AS doctor_name
          FROM 
              consultations c
          JOIN 
              doctors d ON c.doctor_id = d.id
          JOIN
              users u ON d.user_id = u.id
          WHERE 
              c.patient_id = $1
          ORDER BY
              c.created_at DESC
      `;
      
      const result = await pool.query(query, [patient_id]);
      
      res.status(200).json(result.rows);
    } catch (error) {
      console.error('Error getting patient consultations:', error);
      res.status(500).json({ message: "Server error" });
    }
  }

  static async getPatientIdByUserId(req, res) {
    try {
      const { user_id } = req.params;
      
      // Query to get patient ID by user ID
      const query = `
          SELECT id FROM patients WHERE user_id = $1
      `;
      
      const result = await pool.query(query, [user_id]);
      
      if (result.rows.length === 0) {
        return res.status(404).json({ message: "Patient not found" });
      }
      
      res.status(200).json(result.rows[0]);
    } catch (error) {
      console.error('Error getting patient ID by user ID:', error);
      res.status(500).json({ message: "Server error" });
    }
  }
}

module.exports = PatientController;