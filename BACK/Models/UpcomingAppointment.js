// controllers/UpcomingAppointmentController.js
const UpcomingAppointment = require('../Models/UpcomingAppointment');
const Doctor = require('../Models/Doctor');

class UpcomingAppointmentController {
    // Get upcoming appointments for a doctor
   // In controllers/UpcomingAppointmentController.js
// In Models/UpcomingAppointment.js
static async getDoctorUpcomingAppointments(doctorId) {
    try {
      console.log('Getting upcoming appointments for doctor ID:', doctorId);
      
      const query = `
        SELECT 
          c.id AS consultation_id,
          c.patient_id,
          c.status,
          c.type,
          c.is_emergency,
          c.consultation_date,
          u.full_name AS patient_name,
          p.age AS patient_age,
          p.gender AS patient_gender,
          c.created_at
        FROM 
          consultations c
        JOIN 
          patients p ON c.patient_id = p.id
        JOIN 
          users u ON p.user_id = u.id
        WHERE 
          c.doctor_id = $1
          AND c.status = 'accepted'
        ORDER BY 
          c.consultation_date ASC;
      `;
      
      const result = await pool.query(query, [doctorId]);
      console.log(`Found ${result.rows.length} upcoming appointments`);
      
      return result.rows;
    } catch (error) {
      console.error('Error in getDoctorUpcomingAppointments:', error);
      throw error;
    }
  }

    // Count upcoming appointments for a doctor
    static async countDoctorUpcomingAppointments(req, res) {
        try {
            const userId = req.params.doctor_id;
            
            // Get the doctor record by user ID
            const doctor = await Doctor.getDoctorByUserId(userId);
            if (!doctor) {
                return res.status(404).json({ message: "Doctor not found" });
            }
            
            // Count upcoming appointments with the doctor ID
            const upcomingCount = await UpcomingAppointment.countDoctorUpcomingAppointments(doctor.id);
            
            res.status(200).json({ upcoming_count: upcomingCount });
        } catch (error) {
            console.error('Error in countDoctorUpcomingAppointments:', error);
            res.status(500).json({ 
                message: "Server error", 
                error: error.message 
            });
        }
    }

    // Cancel an upcoming appointment
    static async cancelAppointment(req, res) {
        try {
            const consultationId = req.params.consultation_id;
            console.log("Received request to cancel consultation with ID:", consultationId);
            
            if (!consultationId) {
                console.log("Missing consultation_id parameter");
                return res.status(400).json({ message: "Consultation ID is required" });
            }
            
            // Log what we're about to do
            console.log(`Attempting to cancel consultation with ID: ${consultationId}`);
            
            const cancelledAppointment = await UpcomingAppointment.cancelAppointment(consultationId);
            
            if (!cancelledAppointment) {
                console.log(`No appointment found with ID: ${consultationId}`);
                return res.status(404).json({ message: "Appointment not found" });
            }
            
            console.log(`Successfully cancelled appointment: ${JSON.stringify(cancelledAppointment)}`);
            res.status(200).json({ 
                message: "Appointment cancelled successfully", 
                appointment: cancelledAppointment 
            });
        } catch (error) {
            console.error('Error in cancelAppointment:', error);
            res.status(500).json({ 
                message: "Server error", 
                error: error.message 
            });
        }
    }
}

module.exports = UpcomingAppointmentController;