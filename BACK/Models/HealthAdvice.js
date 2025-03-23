// Models/HealthAdvice.js
const pool = require('../config/db');

class HealthAdvice {
    // Create new health advice
    static async createHealthAdvice(doctor_id, title, advice_text, category = 'General') {
        try {
            const result = await pool.query(
                `INSERT INTO health_advice (doctor_id, title, advice_text, category, created_at) 
                 VALUES ($1, $2, $3, $4, NOW()) 
                 RETURNING *`,
                [doctor_id, title, advice_text, category]
            );
            return result.rows[0];
        } catch (error) {
            console.error('Error creating health advice:', error);
            throw error;
        }
    }

    // Get all health advice
    static async getAllHealthAdvice() {
        try {
            const result = await pool.query(`
                SELECT ha.*, d.specialties
                FROM health_advice ha
                JOIN doctors d ON ha.doctor_id = d.id
                ORDER BY ha.created_at DESC
            `);
            return result.rows;
        } catch (error) {
            console.error('Error getting all health advice:', error);
            throw error;
        }
    }

    // Get health advice by ID
    static async getHealthAdviceById(id) {
        try {
            const result = await pool.query(`
                SELECT ha.*, d.specialties
                FROM health_advice ha
                JOIN doctors d ON ha.doctor_id = d.id
                WHERE ha.id = $1
            `, [id]);
            
            return result.rows.length ? result.rows[0] : null;
        } catch (error) {
            console.error('Error getting health advice by ID:', error);
            throw error;
        }
    }

    // Update health advice
    static async updateHealthAdvice(id, advice_text, title, category) {
        try {
            const result = await pool.query(`
                UPDATE health_advice
                SET advice_text = $1, 
                    title = $2, 
                    category = $3, 
                    updated_at = NOW()
                WHERE id = $4
                RETURNING *
            `, [advice_text, title, category, id]);
            
            return result.rows.length ? result.rows[0] : null;
        } catch (error) {
            console.error('Error updating health advice:', error);
            throw error;
        }
    }

    // Delete health advice
    static async deleteHealthAdvice(id) {
        try {
            await pool.query(`
                DELETE FROM health_advice
                WHERE id = $1
            `, [id]);
            
            return true;
        } catch (error) {
            console.error('Error deleting health advice:', error);
            throw error;
        }
    }

    // Get health advice by category
    static async getHealthAdviceByCategory(category) {
        try {
            const result = await pool.query(`
                SELECT ha.*, d.specialties
                FROM health_advice ha
                JOIN doctors d ON ha.doctor_id = d.id
                WHERE ha.category = $1
                ORDER BY ha.created_at DESC
            `, [category]);
            
            return result.rows;
        } catch (error) {
            console.error('Error getting health advice by category:', error);
            throw error;
        }
    }

    // Get health advice by doctor ID
    static async getHealthAdviceByDoctorId(doctorId) {
        try {
            const result = await pool.query(`
                SELECT ha.*, d.specialties
                FROM health_advice ha
                JOIN doctors d ON ha.doctor_id = d.id
                WHERE ha.doctor_id = $1
                ORDER BY ha.created_at DESC
            `, [doctorId]);
            
            return result.rows;
        } catch (error) {
            console.error('Error getting health advice by doctor ID:', error);
            throw error;
        }
    }

    // Add to the HealthAdvice model:

// Get only approved health advice (for patients)
static async getApprovedHealthAdvice() {
    try {
        const result = await pool.query(`
            SELECT ha.*, d.specialties
            FROM health_advice ha
            JOIN doctors d ON ha.doctor_id = d.id
            WHERE ha.is_approved = TRUE
            ORDER BY ha.created_at DESC
        `);
        return result.rows;
    } catch (error) {
        console.error('Error getting approved health advice:', error);
        throw error;
    }
}

// Admin: Approve health advice
static async approveHealthAdvice(id) {
    try {
        const result = await pool.query(`
            UPDATE health_advice
            SET is_approved = TRUE, 
                updated_at = NOW()
            WHERE id = $1
            RETURNING *
        `, [id]);
        
        return result.rows.length ? result.rows[0] : null;
    } catch (error) {
        console.error('Error approving health advice:', error);
        throw error;
    }
}
}

module.exports = HealthAdvice;