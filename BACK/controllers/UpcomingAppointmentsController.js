// controllers/UpcomingAppointmentController.js
const UpcomingAppointment = require('../Models/UpcomingAppointment');
const Doctor = require('../Models/Doctor');

class UpcomingAppointmentController {
    // Get upcoming appointments for a doctor
    static async getDoctorUpcomingAppointments(req, res) {
        try {
            const doctorId = req.params.doctor_id;
            console.log('Received request for doctor_id:', doctorId);
            
            // Validate doctor ID
            const doctor = await Doctor.getDoctorById(doctorId);
            if (!doctor) {
                console.log(`Doctor with ID ${doctorId} not found`);
                return res.status(404).json({ message: "Doctor not found" });
            }
            
            console.log(`Found doctor with ID ${doctorId}, proceeding to fetch appointments`);
            
            // Fetch upcoming appointments
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
            const doctorId = req.params.doctor_id;
            
            // Validate doctor ID
            const doctor = await Doctor.getDoctorById(doctorId);
            if (!doctor) {
                return res.status(404).json({ message: "Doctor not found" });
            }
            
            // Count upcoming appointments
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