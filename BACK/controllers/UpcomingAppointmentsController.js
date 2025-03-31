// controllers/UpcomingAppointmentsController.js
const UpcomingAppointment = require('../Models/UpcomingAppointment');
const Doctor = require('../Models/Doctor');

class UpcomingAppointmentController {
    // Get upcoming appointments for a doctor
    static async getDoctorUpcomingAppointments(req, res) {
        try {
            const userId = req.params.doctor_id;
            console.log('Received request for doctor_id:', userId);
            
            // Try to parse as integer if it's a string
            const userIdNum = parseInt(userId);
            
            let doctorId;
            
            // Try direct doctor ID first
            if (!isNaN(userIdNum)) {
                // Check if this is directly a doctor ID
                const doctorDirectCheck = await pool.query('SELECT id FROM doctors WHERE id = $1', [userIdNum]);
                if (doctorDirectCheck.rows.length > 0) {
                    doctorId = userIdNum;
                    console.log(`Using direct doctor ID: ${doctorId}`);
                } else {
                    // Then try as a user ID to get doctor ID
                    const doctor = await Doctor.getDoctorByUserId(userIdNum);
                    if (doctor) {
                        doctorId = doctor.id;
                        console.log(`Found doctor ID ${doctorId} for user ID ${userId}`);
                    } else {
                        console.log(`No doctor found for user ID ${userId}`);
                        return res.status(404).json({ message: "Doctor not found" });
                    }
                }
            } else {
                return res.status(400).json({ message: "Invalid doctor ID format" });
            }
            
            // Fetch upcoming appointments using the doctor ID
            const appointments = await UpcomingAppointment.getDoctorUpcomingAppointments(doctorId);
            
            console.log(`Returning ${appointments.length} appointments`);
            res.status(200).json(appointments);
        } catch (error) {
            console.error('Error in getDoctorUpcomingAppointments:', error);
            res.status(500).json({ 
                message: "Server error", 
                error: error.message 
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