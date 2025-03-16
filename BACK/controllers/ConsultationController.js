const Consultation = require('../Models/Consultation');
const requestConsultation = async (req, res) => {
    try {
        const { patient_id, doctor_id, is_emergency, type } = req.body;

        // Validate the type (optional but recommended)
        const validTypes = ["text", "voice", "video"];
        const consultationType = validTypes.includes(type) ? type : "text"; // Default to text if invalid

        // Create the consultation
        const newConsultation = await Consultation.createConsultation(
            patient_id, 
            doctor_id, 
            is_emergency, 
            consultationType // Pass the validated type
        );

        res.status(201).json(newConsultation);
    } catch (error) {
        console.error("Error in requestConsultation:", error.message);
        res.status(500).json({ error: "Internal server error", details: error.message });
    }
};

const getDoctorConsultations = async (req, res) => {
    try {
        const { doctor_id } = req.params;
        const consultations = await Consultation.getDoctorConsultations(doctor_id);
        res.json(consultations);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
    }
};

const updateConsultationStatus = async (req, res) => {
    try {
        const { consultation_id, status, consultation_date } = req.body;

        // Ensure status is valid
        const validStatuses = ["pending", "accepted", "rejected", "completed"];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({ message: "Invalid status value" });
        }

        // If accepting, ensure date is provided
        if (status === "accepted" && !consultation_date) {
            return res.status(400).json({ message: "Consultation date is required when accepting a request." });
        }

        // Update consultation status
        const updatedConsultation = await Consultation.updateStatus(consultation_id, status, consultation_date);

        res.json({ message: "Consultation status updated", consultation: updatedConsultation });
    } catch (error) {
        console.error("Error updating consultation status:", error.message);
        res.status(500).json({ error: error.message });
    }
};


module.exports = { requestConsultation, getDoctorConsultations, updateConsultationStatus };
