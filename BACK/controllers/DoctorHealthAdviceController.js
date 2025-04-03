// controllers/DoctorHealthAdviceController.js


class DoctorHealthAdviceController {
    // Create new health advice
    static async createAdvice(req, res) {
        try {
            const { title, content, category, doctor_id } = req.body;
            
            // Validate required fields
            if (!title || !content) {
                return res.status(400).json({ message: "Title and content are required" });
            }
            
            // Check if doctor exists
            const doctor = await Doctor.getDoctorById(doctor_id);
            if (!doctor) {
                return res.status(404).json({ message: "Doctor not found" });
            }
            
            // Create health advice
            const newAdvice = await DoctorHealthAdvice.createAdvice(
                doctor_id, 
                title,
                content,
                category || 'General Health'
            );
            
            res.status(201).json({
                message: "Health advice created successfully",
                advice: newAdvice
            });
        } catch (error) {
            console.error("Error creating health advice:", error);
            res.status(500).json({ message: "Server error" });
        }
    }
    
    // Get health advice by ID
    static async getAdviceById(req, res) {
        try {
            const { id } = req.params;
            const advice = await DoctorHealthAdvice.getAdviceById(id);
            
            if (!advice) {
                return res.status(404).json({ message: "Health advice not found" });
            }
            
            // For non-approved advice, check if requester is the doctor or admin
            if (!advice.is_approved) {
                // If there's a user in the request (authenticated)
                if (req.user) {
                    // Check if admin role
                    if (req.user.role === 'admin') {
                        // Admin can see any advice
                        return res.status(200).json(advice);
                    }
                    
                    // For doctors, check if they're the author
                    const doctorId = await Doctor.getDoctorIdByUserId(req.user.id);
                    if (doctorId && doctorId === advice.doctor_id) {
                        return res.status(200).json(advice);
                    }
                }
                
                // If not admin or author, don't show non-approved advice
                return res.status(403).json({ message: "You don't have permission to view this advice" });
            }
            
            // If approved, anyone can see it
            res.status(200).json(advice);
        } catch (error) {
            console.error("Error fetching health advice:", error);
            res.status(500).json({ message: "Server error" });
        }
    }
    
    // Get all health advice by doctor
    static async getAdviceByDoctor(req, res) {
        try {
            const { doctor_id } = req.params;
            
            // Check if the requested doctor matches the authenticated doctor
            // This prevents doctors from seeing other doctors' drafts
            if (req.user.role === 'doctor') {
                const doctorId = await Doctor.getDoctorIdByUserId(req.user.id);
                
                // If doctor is trying to access another doctor's advice
                if (doctorId != doctor_id) {
                    // Only show approved advice from other doctors
                    const advice = await DoctorHealthAdvice.getAllApprovedAdvice();
                    const filteredAdvice = advice.filter(a => a.doctor_id == doctor_id);
                    return res.status(200).json(filteredAdvice);
                }
            }
            
            // Doctor viewing their own advice or admin viewing any doctor's advice
            const advice = await DoctorHealthAdvice.getAdviceByDoctorId(doctor_id);
            res.status(200).json(advice);
        } catch (error) {
            console.error("Error fetching doctor's health advice:", error);
            res.status(500).json({ message: "Server error" });
        }
    }
    
    // Get all approved health advice
    static async getAllApprovedAdvice(req, res) {
        try {
            const advice = await DoctorHealthAdvice.getAllApprovedAdvice();
            res.status(200).json(advice);
        } catch (error) {
            console.error("Error fetching approved health advice:", error);
            res.status(500).json({ message: "Server error" });
        }
    }
    
    // Get approved health advice by category
    static async getApprovedAdviceByCategory(req, res) {
        try {
            const { category } = req.params;
            const advice = await DoctorHealthAdvice.getApprovedAdviceByCategory(category);
            res.status(200).json(advice);
        } catch (error) {
            console.error("Error fetching health advice by category:", error);
            res.status(500).json({ message: "Server error" });
        }
    }
    
    // Update health advice
    static async updateAdvice(req, res) {
        try {
            const { id } = req.params;
            const { title, content, category } = req.body;
            
            // Validate required fields
            if (!title || !content) {
                return res.status(400).json({ message: "Title and content are required" });
            }
            
            // Check if advice exists
            const advice = await DoctorHealthAdvice.getAdviceById(id);
            if (!advice) {
                return res.status(404).json({ message: "Health advice not found" });
            }
            
            // Check if the user is the doctor who created the advice
            if (req.user.role === 'doctor') {
                const doctorId = await Doctor.getDoctorIdByUserId(req.user.id);
                if (doctorId != advice.doctor_id) {
                    return res.status(403).json({ message: "You can only update your own health advice" });
                }
            }
            
            // Update advice
            const updatedAdvice = await DoctorHealthAdvice.updateAdvice(id, title, content, category);
            
            res.status(200).json({
                message: "Health advice updated successfully",
                advice: updatedAdvice
            });
        } catch (error) {
            console.error("Error updating health advice:", error);
            res.status(500).json({ message: "Server error" });
        }
    }
    
    // Delete health advice
    static async deleteAdvice(req, res) {
        try {
            const { id } = req.params;
            
            // Check if advice exists
            const advice = await DoctorHealthAdvice.getAdviceById(id);
            if (!advice) {
                return res.status(404).json({ message: "Health advice not found" });
            }
            
            // Check permissions (admin can delete any, doctors can only delete their own)
            if (req.user.role === 'doctor') {
                const doctorId = await Doctor.getDoctorIdByUserId(req.user.id);
                if (doctorId != advice.doctor_id) {
                    return res.status(403).json({ message: "You can only delete your own health advice" });
                }
            }
            
            // Delete advice
            await DoctorHealthAdvice.deleteAdvice(id);
            
            res.status(200).json({ message: "Health advice deleted successfully" });
        } catch (error) {
            console.error("Error deleting health advice:", error);
            res.status(500).json({ message: "Server error" });
        }
    }
    
    // Admin: Approve health advice
    static async approveAdvice(req, res) {
        try {
            const { id } = req.params;
            
            // Check if advice exists
            const advice = await DoctorHealthAdvice.getAdviceById(id);
            if (!advice) {
                return res.status(404).json({ message: "Health advice not found" });
            }
            
            // Only admins can approve
            if (req.user.role !== 'admin') {
                return res.status(403).json({ message: "Only administrators can approve health advice" });
            }
            
            // Approve advice
            const approvedAdvice = await DoctorHealthAdvice.approveAdvice(id);
            
            res.status(200).json({
                message: "Health advice approved successfully",
                advice: approvedAdvice
            });
        } catch (error) {
            console.error("Error approving health advice:", error);
            res.status(500).json({ message: "Server error" });
        }
    }
    
    // Admin: Get all pending advice
    static async getPendingAdvice(req, res) {
        try {
            // Only admins can see all pending advice
            if (req.user.role !== 'admin') {
                return res.status(403).json({ message: "Only administrators can view all pending advice" });
            }
            
            const pendingAdvice = await DoctorHealthAdvice.getPendingAdvice();
            res.status(200).json(pendingAdvice);
        } catch (error) {
            console.error("Error fetching pending health advice:", error);
            res.status(500).json({ message: "Server error" });
        }
    }
}

module.exports = DoctorHealthAdviceController;