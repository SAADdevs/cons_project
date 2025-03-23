const pool = require('../config/db');

class Patient {
    // Create a new patient record
    static async createPatient(userId, age, gender) {
        try {
            const query = `
                INSERT INTO patients (user_id, age, gender, created_at) 
                VALUES ($1, $2, $3, NOW()) 
                RETURNING *
            `;
            const result = await pool.query(query, [userId, age, gender]);
            return result.rows[0];
        } catch (error) {
            console.error("Error creating patient:", error);
            throw new Error("Database error while creating patient.");
        }
    }

    // Get patient details by user ID
    static async getPatientByUserId(userId) {
        try {
            const query = `
                SELECT p.*, u.full_name, u.email 
                FROM patients p
                JOIN users u ON p.user_id = u.id
                WHERE p.user_id = $1
            `;
            const result = await pool.query(query, [userId]);
            return result.rows.length ? result.rows[0] : null;
        } catch (error) {
            console.error("Error fetching patient by user ID:", error);
            throw new Error("Database error while retrieving patient details.");
        }
    }
    
    // Get patient details by patient ID
    static async getPatientById(patientId) {
        try {
            const query = `
                SELECT p.*, u.full_name, u.email 
                FROM patients p
                JOIN users u ON p.user_id = u.id
                WHERE p.id = $1
            `;
            const result = await pool.query(query, [patientId]);
            return result.rows.length ? result.rows[0] : null;
        } catch (error) {
            console.error("Error fetching patient by ID:", error);
            throw new Error("Database error while retrieving patient details.");
        }
    }

    // Update patient's age and gender by user ID
    static async updatePatientByUserId(userId, age, gender) {
        try {
            const query = `
                UPDATE patients 
                SET age = $1, gender = $2
                WHERE user_id = $3
                RETURNING *
            `;
            const result = await pool.query(query, [age, gender, userId]);
            return result.rows.length ? result.rows[0] : null;
        } catch (error) {
            console.error("Error updating patient details by user ID:", error);
            throw new Error("Database error while updating patient details.");
        }
    }
    
    // Update patient's age and gender by patient ID
    static async updatePatient(patientId, age, gender) {
        try {
            const query = `
                UPDATE patients 
                SET age = $1, gender = $2
                WHERE id = $3
                RETURNING *
            `;
            const result = await pool.query(query, [age, gender, patientId]);
            return result.rows.length ? result.rows[0] : null;
        } catch (error) {
            console.error("Error updating patient details:", error);
            throw new Error("Database error while updating patient details.");
        }
    }

    // Fetch all consultations of a patient by patient ID
    static async getPatientConsultations(patientId) {
        try {
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
            return result.rows;
        } catch (error) {
            console.error("Error fetching consultations:", error);
            throw new Error("Database error while retrieving consultations.");
        }
    }

    // Fetch a specific consultation with details
    static async getConsultationDetails(consultationId, patientId) {
        try {
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
                    c.id = $1 AND c.patient_id = $2
            `;
            const result = await pool.query(query, [consultationId, patientId]);
            return result.rows.length ? result.rows[0] : null;
        } catch (error) {
            console.error("Error fetching consultation details:", error);
            throw new Error("Database error while retrieving consultation details.");
        }
    }

    // Request a new consultation
    static async requestConsultation(patientId, doctorId, isEmergency, type) {
        try {
            const query = `
                INSERT INTO consultations (patient_id, doctor_id, consultation_date, status, is_emergency, type, created_at)
                VALUES ($1, $2, NOW(), 'pending', $3, $4, NOW())
                RETURNING *
            `;
            const result = await pool.query(query, [patientId, doctorId, isEmergency, type]);
            return result.rows[0];
        } catch (error) {
            console.error("Error requesting consultation:", error);
            throw new Error("Database error while creating consultation request.");
        }
    }

    // Delete patient record
    static async deletePatient(patientId) {
        try {
            const query = `DELETE FROM patients WHERE id = $1 RETURNING *`;
            const result = await pool.query(query, [patientId]);
            return result.rows.length ? result.rows[0] : null;
        } catch (error) {
            console.error("Error deleting patient:", error);
            throw new Error("Database error while deleting patient.");
        }
    }
}

module.exports = Patient;