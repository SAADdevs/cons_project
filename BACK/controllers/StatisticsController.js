// controllers/StatisticsController.js
const pool = require('../config/db');

// Simplified statistics controller with basic error handling
const StatisticsController = {
  // Get all dashboard statistics
  getDashboardStatistics: async (req, res) => {
    try {
      // Get doctors count and pending verification count
      const doctorsQuery = `
        SELECT 
          COUNT(*) as total_doctors,
          COUNT(*) FILTER (WHERE is_verified = false) as pending_verifications
        FROM doctors
      `;
      const doctorsResult = await pool.query(doctorsQuery);
      
      // Get patients count
      const patientsQuery = `SELECT COUNT(*) as total_patients FROM patients`;
      const patientsResult = await pool.query(patientsQuery);
      
      // Get consultations count
      const consultationsQuery = `SELECT COUNT(*) as total_consultations FROM consultations`;
      const consultationsResult = await pool.query(consultationsQuery);
      
      // Get pending health advice count
      const healthAdviceQuery = `
        SELECT COUNT(*) FILTER (WHERE is_approved = false) as pending_advice 
        FROM health_advice
      `;
      const healthAdviceResult = await pool.query(healthAdviceQuery);
      
      // Format the response
      const statistics = {
        doctors: {
          total: parseInt(doctorsResult.rows[0].total_doctors) || 0,
          pending: parseInt(doctorsResult.rows[0].pending_verifications) || 0
        },
        patients: {
          total: parseInt(patientsResult.rows[0].total_patients) || 0
        },
        consultations: {
          total: parseInt(consultationsResult.rows[0].total_consultations) || 0
        },
        healthAdvice: {
          pending: parseInt(healthAdviceResult.rows[0].pending_advice) || 0
        }
      };
      
      res.status(200).json(statistics);
    } catch (error) {
      console.error('Error getting dashboard statistics:', error);
      res.status(500).json({ 
        message: "Error fetching statistics", 
        error: error.message 
      });
    }
  }
};

module.exports = StatisticsController;