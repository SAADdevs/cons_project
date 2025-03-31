// controllers/UpcomingAppointmentController.js
const UpcomingAppointment = require('../Models/UpcomingAppointment');
const Doctor = require('../Models/Doctor');

class UpcomingAppointmentController {
    // Get upcoming appointments for a doctor
   // In controllers/UpcomingAppointmentController.js
static async getDoctorUpcomingAppointments(req, res) {
    try {
        const userId = req.params.doctor_id;
        console.log('Received request for user_id:', userId);
        
        // First get the doctor record by user ID
        const doctor = await Doctor.getDoctorByUserId(userId);
        if (!doctor) {
            console.log(`Doctor with user ID ${userId} not found`);
            return res.status(404).json({ message: "Doctor not found" });
        }
        
        const doctorId = doctor.id;
        console.log(`Found doctor ID ${doctorId} for user ID ${userId}, proceeding to fetch appointments`);
        
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