// controllers/UpcomingAppointmentsController.js
const UpcomingAppointment = require('../Models/UpcomingAppointment');
const Doctor = require('../Models/Doctor');
const pool = require('../config/db'); // Add this import statement

class UpcomingAppointmentController {
    // Get upcoming appointments for a doctor
   // Fix in UpcomingAppointmentController.js
// controllers/UpcomingAppointmentsController.js
static async getDoctorUpcomingAppointments(req, res) {
    try {
        const inputDoctorId = req.params.doctor_id;
        console.log('------- DETAILED APPOINTMENT RETRIEVAL -------');
        console.log(`Received doctor_id: ${inputDoctorId}`);

        // Ensure input is a number
        const doctorId = parseInt(inputDoctorId, 10);
        if (isNaN(doctorId)) {
            console.error('Invalid doctor ID format');
            return res.status(400).json({ 
                message: "Invalid doctor ID format",
                receivedId: inputDoctorId 
            });
        }

        // First, verify the doctor exists
        const doctorCheck = await pool.query(
            'SELECT id FROM doctors WHERE id = $1 OR user_id = $1', 
            [doctorId]
        );

        if (doctorCheck.rows.length === 0) {
            console.error(`No doctor found matching ID: ${doctorId}`);
            return res.status(404).json({ 
                message: "Doctor not found",
                searchedId: doctorId 
            });
        }

        // Determine the correct doctor ID
        const correctDoctorId = doctorCheck.rows[0].id;
        console.log(`Resolved Doctor ID: ${correctDoctorId}`);

        // Comprehensive query to fetch upcoming appointments
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
        
        const result = await pool.query(query, [correctDoctorId]);
        
        console.log(`Found ${result.rows.length} upcoming appointments`);
        
        // Log detailed appointment information
        result.rows.forEach((apt, index) => {
            console.log(`Appointment ${index + 1}:`, {
                id: apt.consultation_id,
                patientName: apt.patient_name,
                date: apt.consultation_date,
                type: apt.type
            });
        });

        console.log('------- END OF APPOINTMENT RETRIEVAL -------');
        
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Comprehensive Error in Appointment Retrieval:', error);
        res.status(500).json({ 
            message: "Server error", 
            errorDetails: error.message,
            stack: error.stack
        });
    }
}

    // Count upcoming appointments for a doctor
    static async countDoctorUpcomingAppointments(req, res) {
        try {
            const userId = req.params.doctor_id;
            
            // Try to parse as integer if it's a string
            const userIdNum = parseInt(userId);
            
            let doctorId;
            
            // Try direct doctor ID first
            if (!isNaN(userIdNum)) {
                // Check if this is directly a doctor ID
                const doctorDirectCheck = await pool.query('SELECT id FROM doctors WHERE id = $1', [userIdNum]);
                if (doctorDirectCheck.rows.length > 0) {
                    doctorId = userIdNum;
                } else {
                    // Then try as a user ID to get doctor ID
                    const doctor = await Doctor.getDoctorByUserId(userIdNum);
                    if (doctor) {
                        doctorId = doctor.id;
                    } else {
                        return res.status(404).json({ message: "Doctor not found" });
                    }
                }
            } else {
                return res.status(400).json({ message: "Invalid doctor ID format" });
            }
            
            // Count upcoming appointments with the doctor ID
            const upcomingCount = await UpcomingAppointment.countDoctorUpcomingAppointments(doctorId);
            
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
            
            // Try to parse as integer if it's a string
            const consultationIdNum = parseInt(consultationId);
            
            if (isNaN(consultationIdNum)) {
                return res.status(400).json({ message: "Invalid consultation ID format" });
            }
            
            // Log what we're about to do
            console.log(`Attempting to cancel consultation with ID: ${consultationIdNum}`);
            
            const cancelledAppointment = await UpcomingAppointment.cancelAppointment(consultationIdNum);
            
            if (!cancelledAppointment) {
                console.log(`No appointment found with ID: ${consultationIdNum}`);
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