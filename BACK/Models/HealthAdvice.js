const pool = require('../config/db');

class HealthAdvice {
    static async createHealthAdvice(doctor_id, advice_text) {
        const result = await pool.query(
            'INSERT INTO health_advice (doctor_id, advice_text) VALUES ($1, $2) RETURNING *',
            [doctor_id, advice_text]
        );
        return result.rows[0];
    }

    static async getAllHealthAdvice() {
        const result = await pool.query('SELECT * FROM health_advice');
        return result.rows;
    }
}

module.exports = HealthAdvice;
