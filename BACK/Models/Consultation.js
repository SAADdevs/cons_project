const pool = require('../config/db');

class Consultation {
   // Update your Consultation model method
   static async createConsultation(patient_id, doctor_id, is_emergency, type = "text") {
    const result = await pool.query(
        `INSERT INTO consultations (patient_id, doctor_id, consultation_date, status, is_emergency, type, created_at)
         VALUES ($1, $2, NOW(), 'pending', $3, $4, NOW())
         RETURNING *`,
        [patient_id, doctor_id, is_emergency, type]
    );

    return result.rows[0];
}

    static async getDoctorConsultations(doctor_id) {
        const result = await pool.query(`
            SELECT c.*, p.name as patient_name
            FROM consultations c
            JOIN patients p ON c.patient_id = p.id
            WHERE c.doctor_id = ?
          `, [doctorId]);
        return result.rows;
    }

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
