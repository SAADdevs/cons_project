// models/Doctor.js
const pool = require('../config/db');

class Doctor {
    // Insert doctor details after user registration
    static async createDoctor(userId, IMPE, specialties, hospital) {
        const query = `
            INSERT INTO doctors (user_id, IMPE, specialties, hospital, is_verified, is_available) 
            VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`;
        const result = await pool.query(query, [userId, IMPE, specialties, hospital, false, true]); // Initially unverified
        return result.rows[0];
    }

    // Check if a doctor is verified
    static async isDoctorVerified(userId) {
        const query = 'SELECT is_verified FROM doctors WHERE user_id = $1';
        const result = await pool.query(query, [userId]);
        return result.rows[0]?.is_verified || false;
    }

    static async getDoctorById(id) {
        const result = await pool.query("SELECT * FROM doctors WHERE id = $1", [id]);
        return result.rows[0]; // return the first result (or null if not found)
    }

    // Approve doctor
    static async approveDoctor(id) {
        await pool.query("UPDATE doctors SET is_verified = $1 WHERE id = $2", [true, id]);
    }

    // Get all doctors
    static async getAllDoctors() {
        const result = await pool.query("SELECT * FROM doctors");
        return result.rows; // return all doctors
    }

    static async updateAvailability(doctor_id, is_available) {
        const result = await pool.query(
            "UPDATE doctors SET is_available = $1 WHERE id = $2 RETURNING *",
            [is_available, doctor_id]
        );
        return result.rows[0]; // Return updated doctor data
    }
    
    // Get doctor by user ID (fixed - removed duplicate)
    static async getDoctorByUserId(userId) {
        try {
            const result = await pool.query(
                "SELECT * FROM doctors WHERE user_id = $1",
                [userId]
            );
            
            if (result.rows.length === 0) {
                return null;
            }
            
            return result.rows[0];
        } catch (error) {
            console.error("Error in getDoctorByUserId:", error);
            throw error;
        }
    }
    
    // Get doctors by specialty with their names
    static async getDoctorsBySpecialtyWithNames(specialty) {
        try {
            const result = await pool.query(`
                SELECT d.*, u.full_name 
                FROM doctors d
                JOIN users u ON d.user_id = u.id
                WHERE d.specialties ILIKE $1 AND d.is_verified = true
                ORDER BY u.full_name
            `, [`%${specialty}%`]);
            
            return result.rows;
        } catch (error) {
            console.error("Error getting doctors by specialty with names:", error);
            throw error;
        }
    }
}

module.exports = Doctor;