// Models/UpcomingAppointment.js
const pool = require('../config/db');

class UpcomingAppointment {
    // Fetch upcoming appointments for a specific doctor
    static async getDoctorUpcomingAppointments(doctorId) {
        try {
            console.log('Fetching upcoming appointments for doctor_id:', doctorId);
            console.log('Current server time:', new Date());
    
            const query = `
                WITH consultation_details AS (
                    SELECT 
                        c.id AS consultation_id,
                        c.patient_id,
                        c.doctor_id,
                        c.consultation_date,
                        c.type,
                        c.status,
                        c.is_emergency,
                        p.user_id AS patient_user_id
                    FROM 
                        consultations c
                    JOIN 
                        patients p ON c.patient_id = p.id
                    WHERE 
                        c.doctor_id = $1
                        AND c.status = 'accepted'
                )
                SELECT 
                    cd.consultation_id,
                    cd.consultation_date,
                    cd.type,
                    cd.status,
                    cd.is_emergency,
                    u.id AS user_id,
                    u.full_name AS patient_name,
                    p.age AS patient_age,
                    p.gender AS patient_gender
                FROM 
                    consultation_details cd
                JOIN 
                    users u ON cd.patient_user_id = u.id
                JOIN 
                    patients p ON p.user_id = u.id
                ORDER BY 
                    cd.consultation_date ASC
            `;
    
            console.log('Executing query with doctor_id:', doctorId);
            const result = await pool.query(query, [doctorId]);
    
            console.log(`Found ${result.rows.length} upcoming appointments`);
            if (result.rows.length > 0) {
                console.log('First appointment:', result.rows[0]);
            }
    
            return result.rows;
        } catch (error) {
            console.error('Detailed error in getDoctorUpcomingAppointments:', error);
            throw error;
        }
    }

    // Count upcoming appointments for a doctor
    static async countDoctorUpcomingAppointments(doctorId) {
        try {
            const query = `
                SELECT COUNT(*) AS upcoming_count
                FROM consultations
                WHERE 
                    doctor_id = $1 
                    AND status = 'accepted'
                    AND consultation_date > NOW()
            `;
            
            const result = await pool.query(query, [doctorId]);
            return parseInt(result.rows[0].upcoming_count);
        } catch (error) {
            console.error('Error counting upcoming appointments:', error);
            throw error;
        }
    }

    // Cancel an upcoming appointment
    // Models/UpcomingAppointment.js - Updated cancelAppointment method

// Cancel an upcoming appointment
static async cancelAppointment(consultationId) {
    try {
        console.log(`Executing cancellation query for consultation_id: ${consultationId}`);
        
        // First, check if the consultation exists
        const checkQuery = `
            SELECT id, status FROM consultations WHERE id = $1
        `;
        const checkResult = await pool.query(checkQuery, [consultationId]);
        
        if (checkResult.rows.length === 0) {
            console.log(`No consultation found with ID: ${consultationId}`);
            return null;
        }
        
        console.log(`Found consultation: ${JSON.stringify(checkResult.rows[0])}`);
        
        // Use a value that's allowed by your constraint: 'rejected' instead of 'cancelled'
        const query = `
            UPDATE consultations 
            SET status = 'rejected' 
            WHERE id = $1 
            RETURNING *
        `;
        
        const result = await pool.query(query, [consultationId]);
        
        if (result.rows.length > 0) {
            console.log(`Successfully cancelled: ${JSON.stringify(result.rows[0])}`);
            return result.rows[0];
        } else {
            console.log(`Update query didn't affect any rows for ID: ${consultationId}`);
            return null;
        }
    } catch (error) {
        console.error('Error cancelling appointment:', error);
        throw error;
    }
}
}

module.exports = UpcomingAppointment;