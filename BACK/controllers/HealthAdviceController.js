// controllers/HealthAdviceController.js
const HealthAdvice = require('../Models/HealthAdvice');
const Doctor = require('../Models/Doctor');
const User = require('../Models/User');

class HealthAdviceController {
    // Get all health advice
    static async getAllHealthAdvice(req, res) {
        try {
            const advice = await HealthAdvice.getAllHealthAdvice();
            
            // Get additional doctor info for each advice
            const adviceWithDoctorInfo = await Promise.all(
                advice.map(async (item) => {
                    // Get doctor user info
                    if (item.doctor_id) {
                        const doctor = await Doctor.getDoctorById(item.doctor_id);
                        if (doctor && doctor.user_id) {
                            const user = await User.getUserById(doctor.user_id);
                            return {
                                ...item,
                                doctor_name: user ? user.full_name : 'Unknown Doctor'
                            };
                        }
                    }
                    return item;
                })
            );
            
            res.status(200).json(adviceWithDoctorInfo);
        } catch (error) {
            console.error('Error getting health advice:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get health advice by ID
    static async getHealthAdviceById(req, res) {
        try {
            const { id } = req.params;
            const advice = await HealthAdvice.getHealthAdviceById(id);
            
            if (!advice) {
                return res.status(404).json({ message: "Health advice not found" });
            }
            
            // Get doctor info
            let doctorInfo = {};
            if (advice.doctor_id) {
                const doctor = await Doctor.getDoctorById(advice.doctor_id);
                if (doctor && doctor.user_id) {
                    const user = await User.getUserById(doctor.user_id);
                    doctorInfo = {
                        doctor_name: user ? user.full_name : 'Unknown Doctor'
                    };
                }
            }
            
            res.status(200).json({
                ...advice,
                ...doctorInfo
            });
        } catch (error) {
            console.error('Error getting health advice by ID:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Create new health advice
    static async createHealthAdvice(req, res) {
        try {
            const { title, advice_text, category } = req.body;
            const doctorId = req.body.doctor_id; // Since we're not using middleware
            
            if (!doctorId) {
                return res.status(400).json({ message: "Doctor ID is required" });
            }
            
            if (!title || !advice_text) {
                return res.status(400).json({ message: "Title and advice text are required" });
            }
            
            // Create the health advice
            const newAdvice = await HealthAdvice.createHealthAdvice(
                doctorId, 
                title,
                advice_text, 
                category
            );
            
            res.status(201).json({
                message: "Health advice created successfully",
                advice: newAdvice
            });
        } catch (error) {
            console.error('Error creating health advice:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Update health advice
    static async updateHealthAdvice(req, res) {
        try {
            const { id } = req.params;
            const { title, advice_text, category } = req.body;
            
            // Check if health advice exists
            const advice = await HealthAdvice.getHealthAdviceById(id);
            if (!advice) {
                return res.status(404).json({ message: "Health advice not found" });
            }
            
            // Update the health advice
            const updatedAdvice = await HealthAdvice.updateHealthAdvice(
                id,
                advice_text,
                title,
                category
            );
            
            res.status(200).json({
                message: "Health advice updated successfully",
                advice: updatedAdvice
            });
        } catch (error) {
            console.error('Error updating health advice:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Delete health advice
    static async deleteHealthAdvice(req, res) {
        try {
            const { id } = req.params;
            
            // Check if health advice exists
            const advice = await HealthAdvice.getHealthAdviceById(id);
            if (!advice) {
                return res.status(404).json({ message: "Health advice not found" });
            }
            
            // Delete the health advice
            await HealthAdvice.deleteHealthAdvice(id);
            
            res.status(200).json({ message: "Health advice deleted successfully" });
        } catch (error) {
            console.error('Error deleting health advice:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get health advice by category
    static async getHealthAdviceByCategory(req, res) {
        try {
            const { category } = req.params;
            const advice = await HealthAdvice.getHealthAdviceByCategory(category);
            
            // Get additional doctor info for each advice
            const adviceWithDoctorInfo = await Promise.all(
                advice.map(async (item) => {
                    // Get doctor info
                    if (item.doctor_id) {
                        const doctor = await Doctor.getDoctorById(item.doctor_id);
                        if (doctor && doctor.user_id) {
                            const user = await User.getUserById(doctor.user_id);
                            return {
                                ...item,
                                doctor_name: user ? user.full_name : 'Unknown Doctor'
                            };
                        }
                    }
                    return item;
                })
            );
            
            res.status(200).json(adviceWithDoctorInfo);
        } catch (error) {
            console.error('Error getting health advice by category:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get health advice by doctor ID
    static async getHealthAdviceByDoctor(req, res) {
        try {
            const { doctorId } = req.params;
            const advice = await HealthAdvice.getHealthAdviceByDoctorId(doctorId);
            
            // Get doctor info
            let doctorName = 'Unknown Doctor';
            
            if (advice.length > 0) {
                const doctor = await Doctor.getDoctorById(doctorId);
                if (doctor && doctor.user_id) {
                    const user = await User.getUserById(doctor.user_id);
                    doctorName = user ? user.full_name : 'Unknown Doctor';
                }
            }
            
            // Add doctor info to each advice
            const adviceWithDoctorInfo = advice.map(item => ({
                ...item,
                doctor_name: doctorName
            }));
            
            res.status(200).json(adviceWithDoctorInfo);
        } catch (error) {
            console.error('Error getting health advice by doctor:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Add to HealthAdviceController:

// Get approved health advice (for patients)
static async getApprovedHealthAdvice(req, res) {
    try {
        const advice = await HealthAdvice.getApprovedHealthAdvice();
        
        // Get additional doctor info for each advice (same as getAllHealthAdvice)
        const adviceWithDoctorInfo = await Promise.all(
            advice.map(async (item) => {
                // Get doctor user info
                if (item.doctor_id) {
                    const doctor = await Doctor.getDoctorById(item.doctor_id);
                    if (doctor && doctor.user_id) {
                        const user = await User.getUserById(doctor.user_id);
                        return {
                            ...item,
                            doctor_name: user ? user.full_name : 'Unknown Doctor'
                        };
                    }
                }
                return item;
            })
        );
        
        res.status(200).json(adviceWithDoctorInfo);
    } catch (error) {
        console.error('Error getting approved health advice:', error);
        res.status(500).json({ message: "Server error" });
    }
}

// Admin: Approve health advice
static async approveHealthAdvice(req, res) {
    try {
        const { id } = req.params;
        
        // Check if health advice exists
        const advice = await HealthAdvice.getHealthAdviceById(id);
        if (!advice) {
            return res.status(404).json({ message: "Health advice not found" });
        }
        
        // Approve the health advice
        const updatedAdvice = await HealthAdvice.approveHealthAdvice(id);
        
        res.status(200).json({
            message: "Health advice approved successfully",
            advice: updatedAdvice
        });
    } catch (error) {
        console.error('Error approving health advice:', error);
        res.status(500).json({ message: "Server error" });
    }
}
}

module.exports = HealthAdviceController;