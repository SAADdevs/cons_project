// controllers/PatientController.js
const pool = require('../config/db');
const Patient = require('../Models/Patient');

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
        try {
            const { specialty } = req.params;
            
            // Query to get doctors by specialty
            const query = `
                SELECT d.id, d.user_id, d.specialties, d.hospital, u.full_name
                FROM doctors d
                JOIN users u ON d.user_id = u.id
                WHERE d.specialties ILIKE $1 AND d.is_available = true AND d.is_verified = true
            `;
            
            const result = await pool.query(query, [`%${specialty}%`]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "No doctors found with that specialty" });
            }
            
            res.status(200).json(result.rows);
        } catch (error) {
            console.error('Error getting doctors by specialty:', error);
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
            const { userId_id } = req.params;
            const patientId = await pool.query(
                `select id from patients where user_id = $1`,
                [userId_id]
            );
            console.log(patientId);

            
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
            
            // First try to look up patient by user_id
            let patient = await Patient.getPatientByUserId(parseInt(patient_id));
            
            // If not found, try looking up by patient_id
            if (!patient) {
                patient = await Patient.getPatientById(parseInt(patient_id));
            }
            
            if (!patient) {
                return res.status(404).json({ message: "Patient not found" });
            }
            
            res.status(200).json(patient);
        } catch (error) {
            console.error('Error getting patient profile:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Update patient profile
    static async updatePatientProfile(req, res) {
        try {
            const { patient_id } = req.params; // This would be the user_id in our case
            const { age, gender } = req.body;
            
            console.log(`Updating patient profile for user_id ${patient_id}: Age: ${age}, Gender: ${gender}`);
            
            // Find the patient record with the user_id
            const patient = await Patient.getPatientByUserId(parseInt(patient_id));
            
            if (!patient) {
                return res.status(404).json({ message: "Patient not found" });
            }
            
            // Update the patient details using the user ID
            const updatedPatient = await Patient.updatePatientByUserId(
                parseInt(patient_id), 
                age, 
                gender
            );
            
            res.status(200).json({
                message: "Patient profile updated successfully",
                patient: updatedPatient
            });
        } catch (error) {
            console.error('Error updating patient profile:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    static async createPatient(userId, age, gender) {
        try {
            const result = await pool.query(
                `INSERT INTO patients (user_id, age, gender, created_at)
                 VALUES ($1, $2, $3, NOW())
                 RETURNING *`,
                [userId, age, gender]
            );
            return result.rows[0];
        } catch (error) {
            console.error('Error creating patient:', error);
            throw error;
        }
    }

    // Get patient by user ID
    static async getPatientByUserId(userId) {
        try {
            const result = await pool.query(
                `SELECT p.*, u.full_name, u.email, u.created_at
                 FROM patients p
                 JOIN users u ON p.user_id = u.id
                 WHERE p.user_id = $1`,
                [patientId]
            );
            return result.rows[0];
        } catch (error) {
            console.error('Error getting patient by user ID:', error);
            throw error;
        }
    }

    // Get patient by ID
    static async getPatientById(patientId) {
        try {
            const result = await pool.query(
                `SELECT p.*, u.full_name, u.email, u.created_at
                 FROM patients p
                 JOIN users u ON p.user_id = u.id
                 WHERE p.id = $1`,
                [patientId]
            );
            return result.rows[0];
        } catch (error) {
            console.error('Error getting patient by ID:', error);
            throw error;
        }
    }

    // Update patient by user ID
    static async updatePatientByUserId(userId, age, gender) {
        try {
            const result = await pool.query(
                `UPDATE patients
                 SET age = $2, gender = $3
                 WHERE user_id = $1
                 RETURNING *`,
                [userId, age, gender]
            );
            return result.rows[0];
        } catch (error) {
            console.error('Error updating patient:', error);
            throw error;
        }
    }
}

module.exports = PatientController;