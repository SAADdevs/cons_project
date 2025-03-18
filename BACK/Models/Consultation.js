// Models/Consultation.js
const pool = require('../config/db');

class Consultation {
    // Create consultation
    static async createConsultation(patient_id, doctor_id, is_emergency, type = "text") {
        const result = await pool.query(
            `INSERT INTO consultations (patient_id, doctor_id, consultation_date, status, is_emergency, type, created_at)
       VALUES ($1, $2, NOW(), 'pending', $3, $4, NOW())
       RETURNING *`,
            [patient_id, doctor_id, is_emergency, type]
        );

        return result.rows[0];
    }

    // Get doctor consultations using user_id
    static async getDoctorConsultations(user_ID) {
        try {
            // First get the doctor's ID from the doctors table
            const doctorResult = await pool.query(`
                SELECT d.id FROM doctors d 
                WHERE d.user_id = $1
            `, [user_ID]);
            
            if (doctorResult.rows.length === 0) {
                throw new Error("Doctor not found for user ID: " + user_ID);
            }
            
            const doctorId = doctorResult.rows[0].id;
            console.log("Found doctor ID:", doctorId);
            
            // Now get consultations with that doctor ID
            const result = await pool.query(`
                SELECT 
                    u.id AS user_id,
                    u.full_name AS patient_name,
                    u.email,
                    p.id AS patient_id,
                    p.age,
                    p.gender,
                    c.id AS consultation_id,
                    c.status,
                    c.is_emergency,
                    c.consultation_date,
                    c.created_at AS consultation_created_at,
                    c.type
                FROM 
                    consultations c
                JOIN 
                    patients p ON c.patient_id = p.id
                JOIN
                    users u ON p.user_id = u.id
                WHERE 
                    c.doctor_id = $1
                    AND c.status = 'pending'
                ORDER BY
                    c.created_at DESC
            `, [doctorId]);
            
            console.log("Found consultations:", result.rows.length);
            return result.rows;
        } catch (error) {
            console.error('Error getting doctor consultations:', error);
            throw error;
        }
    }
    // Update consultation status
    static async updateStatus(consultation_id, status, consultation_date = null) {
        // If the doctor is accepting, ensure a date is provided
        if (status === "accepted" && !consultation_date) {
            throw new Error("Consultation date is required when accepting a request.");
        }

        // Update query
        const result = await pool.query(
            "UPDATE consultations SET status = $1, consultation_date = $2 WHERE id = $3 RETURNING *",
            [status, consultation_date, consultation_id]
        );

        if (result.rowCount === 0) {
            throw new Error("Consultation not found");
        }

        return result.rows[0];
    }
}

module.exports = Consultation;