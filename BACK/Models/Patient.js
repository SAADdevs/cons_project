const db = require('../config/db');

class Patient {
    // Create a new patient record
    static async createPatient(userId, age, gender) {
        try {
            const query = `
                INSERT INTO patients (user_id, age, gender, created_at) 
                VALUES ($1, $2, $3, NOW()) 
                RETURNING *
            `;
            const values = [userId, age, gender];
            const { rows } = await db.query(query, values);
            return rows[0];
        } catch (error) {
            console.error("Error creating patient:", error);
            throw new Error("Database error while creating patient.");
        }
    }

    // Get patient details by user ID
    static async getPatientById(userId) {
        try {
            const query = `
                SELECT p.*, u.full_name, u.email 
                FROM patients p
                JOIN users u ON p.user_id = u.id
                WHERE p.user_id = $1
            `;
            const { rows } = await db.query(query, [userId]);
            return rows.length ? rows[0] : null;
        } catch (error) {
            console.error("Error fetching patient:", error);
            throw new Error("Database error while retrieving patient details.");
        }
    }

    // Update patient's age and gender
    static async updatePatient(userId, age, gender) {
        try {
            const query = `
                UPDATE patients 
                SET age = $1, gender = $2
                WHERE user_id = $3
                RETURNING *
            `;
            const values = [age, gender, userId];
            const { rows } = await db.query(query, values);
            return rows.length ? rows[0] : null;
        } catch (error) {
            console.error("Error updating patient details:", error);
            throw new Error("Database error while updating patient details.");
        }
    }

    // Fetch all consultations of a patient
    static async getPatientConsultations(userId) {
        try {
            const query = `
                SELECT c.*, d.full_name AS doctor_name
                FROM consultations c
                JOIN users d ON c.doctor_id = d.id
                WHERE c.patient_id = $1
                ORDER BY c.date DESC
            `;
            const { rows } = await db.query(query, [userId]);
            return rows;
        } catch (error) {
            console.error("Error fetching consultations:", error);
            throw new Error("Database error while retrieving consultations.");
        }
    }

    // Delete patient record
    static async deletePatient(userId) {
        try {
            const query = `DELETE FROM patients WHERE user_id = $1 RETURNING *`;
            const { rows } = await db.query(query, [userId]);
            return rows.length ? rows[0] : null;
        } catch (error) {
            console.error("Error deleting patient:", error);
            throw new Error("Database error while deleting patient.");
        }
    }
}

module.exports = Patient;
