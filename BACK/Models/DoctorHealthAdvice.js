// models/DoctorHealthAdvice.js
const pool = require('../config/db');

class DoctorHealthAdvice {
    // Create a new health advice by a doctor
    static async createAdvice(doctor_id, title, content, category = 'General Health') {
        try {
            const query = `
                INSERT INTO doctor_health_advice (doctor_id, title, content, category, is_approved, created_at)
                VALUES ($1, $2, $3, $4, $5, NOW())
                RETURNING *
            `;
            const values = [doctor_id, title, content, category, false]; // Default to not approved
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (error) {
            console.error("Error creating doctor health advice:", error);
            throw error;
        }
    }
    
    // Get all health advice from a specific doctor
    static async getAdviceByDoctorId(doctor_id) {
        try {
            const query = `
                SELECT * FROM doctor_health_advice
                WHERE doctor_id = $1
                ORDER BY created_at DESC
            `;
            const result = await pool.query(query, [doctor_id]);
            return result.rows;
        } catch (error) {
            console.error("Error getting doctor's health advice:", error);
            throw error;
        }
    }
    
    // Get health advice by ID
    static async getAdviceById(id) {
        try {
            const query = `
                SELECT * FROM doctor_health_advice
                WHERE id = $1
            `;
            const result = await pool.query(query, [id]);
            return result.rows[0];
        } catch (error) {
            console.error("Error getting doctor health advice by ID:", error);
            throw error;
        }
    }
    
    // Get all approved health advice
    static async getAllApprovedAdvice() {
        try {
            const query = `
                SELECT dha.*, d.specialties, u.full_name as doctor_name
                FROM doctor_health_advice dha
                JOIN doctors d ON dha.doctor_id = d.id
                JOIN users u ON d.user_id = u.id
                WHERE dha.is_approved = true
                ORDER BY dha.created_at DESC
            `;
            const result = await pool.query(query);
            return result.rows;
        } catch (error) {
            console.error("Error getting approved doctor health advice:", error);
            throw error;
        }
    }
    
    // Get all approved health advice by category
    static async getApprovedAdviceByCategory(category) {
        try {
            const query = `
                SELECT dha.*, d.specialties, u.full_name as doctor_name
                FROM doctor_health_advice dha
                JOIN doctors d ON dha.doctor_id = d.id
                JOIN users u ON d.user_id = u.id
                WHERE dha.is_approved = true AND dha.category = $1
                ORDER BY dha.created_at DESC
            `;
            const result = await pool.query(query, [category]);
            return result.rows;
        } catch (error) {
            console.error("Error getting doctor health advice by category:", error);
            throw error;
        }
    }
    
    // Update health advice
    static async updateAdvice(id, title, content, category) {
        try {
            const query = `
                UPDATE doctor_health_advice
                SET title = $1, content = $2, category = $3, updated_at = NOW(), is_approved = false
                WHERE id = $4
                RETURNING *
            `;
            const result = await pool.query(query, [title, content, category, id]);
            return result.rows[0];
        } catch (error) {
            console.error("Error updating doctor health advice:", error);
            throw error;
        }
    }
    
    // Delete health advice
    static async deleteAdvice(id) {
        try {
            const query = `
                DELETE FROM doctor_health_advice
                WHERE id = $1
                RETURNING *
            `;
            const result = await pool.query(query, [id]);
            return result.rows[0];
        } catch (error) {
            console.error("Error deleting doctor health advice:", error);
            throw error;
        }
    }
    
    // Approve health advice (for admins)
    static async approveAdvice(id) {
        try {
            const query = `
                UPDATE doctor_health_advice
                SET is_approved = true
                WHERE id = $1
                RETURNING *
            `;
            const result = await pool.query(query, [id]);
            return result.rows[0];
        } catch (error) {
            console.error("Error approving doctor health advice:", error);
            throw error;
        }
    }
    
    // Get all advice waiting for approval (for admins)
    static async getPendingAdvice() {
        try {
            const query = `
                SELECT dha.*, d.specialties, u.full_name as doctor_name
                FROM doctor_health_advice dha
                JOIN doctors d ON dha.doctor_id = d.id
                JOIN users u ON d.user_id = u.id
                WHERE dha.is_approved = false
                ORDER BY dha.created_at DESC
            `;
            const result = await pool.query(query);
            return result.rows;
        } catch (error) {
            console.error("Error getting pending doctor health advice:", error);
            throw error;
        }
    }
}

module.exports = DoctorHealthAdvice;