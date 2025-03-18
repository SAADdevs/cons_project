const Doctor = require('../Models/Doctor'); 
const pool = require('../config/db'); 

class DoctorController {
    // Get all doctors
    static async getAllDoctors(req, res) {
        try {
            const result = await pool.query("SELECT * FROM doctors");
            res.status(200).json(result.rows); // Sending a list of all doctors
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get a doctor by ID
    static async getDoctorById(req, res) {
        try {
            const doctorId = parseInt(req.params.id); // Convert ID to an integer
    
            if (isNaN(doctorId)) {
                return res.status(400).json({ message: "Invalid doctor ID. It must be a number." });
            }
    
            const result = await pool.query("SELECT * FROM doctors WHERE id = $1", [doctorId]);
    
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "Doctor not found" });
            }
            res.status(200).json(result.rows);
        } catch (error) {
            console.error("Database Error:", error);
            res.status(500).json({ message: "Server error", error: error.message });
        }
    }
    

    // Approve a doctor 
    static async approveDoctor(req, res) {
        const { id } = req.params; 
        try {
            const result = await pool.query("SELECT * FROM doctors WHERE id = $1", [id]);
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "Doctor not found" });
            }

            await pool.query("UPDATE doctors SET is_verified = $1 WHERE id = $2", [true, id]);
            res.status(200).json({ message: "Doctor approved successfully" });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get a list of verified doctors
    static async getVerifiedDoctors(req, res) {
        try {
            // Corrected query: Use `true` for boolean comparison
            const result = await pool.query("SELECT * FROM doctors WHERE is_verified = true");
            res.status(200).json(result.rows);
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }


    //Get doctors by specialty
    static async getDoctorsBySpecialty(req, res) {
        const { specialty } = req.params; 
        try {
            const result = await pool.query("SELECT * FROM doctors WHERE specialties LIKE $1", [`%${specialty}%`]);    
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "No doctors found with that specialty" });
            }
    
            res.status(200).json(result.rows);
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }
    
    // Get available doctors
    static async getAvailableDoctors(req, res) {
        try {
            const result = await pool.query(
                "SELECT * FROM doctors WHERE is_available = true"
            );
    
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "No available doctors found" });
            }
    
            res.status(200).json(result.rows);
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }

    static async updateDoctorAvailability(req, res) {
        try {
            const { doctor_id, is_available } = req.body;
            
            // Update the availability status of the doctor
            const result = await pool.query(
                "UPDATE doctors SET is_available = $1 WHERE id = $2 RETURNING *",
                [is_available, doctor_id]
            );
    
            // Check if the doctor exists
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "Doctor not found" });
            }
    
            // Return the updated doctor data
            res.status(200).json({
                message: "Doctor availability updated successfully",
                doctor: result.rows[0]
            });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }

    static async unverifyDoctor(req, res) {
        const { id } = req.params; 
        try {
            const result = await pool.query("SELECT * FROM doctors WHERE id = $1", [id]);
            if (result.rows.length === 0) {
                return res.status(404).json({ message: "Doctor not found" });
            }
    
            await pool.query("UPDATE doctors SET is_verified = $1 WHERE id = $2", [false, id]);
            res.status(200).json({ message: "Doctor unverified successfully" });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Add this method to your DoctorController.js file

// Get all doctors with their names from users table
static async getDoctorsWithNames(req, res) {
    try {
        const query = `
            SELECT d.id, d.user_id, u.full_name, d.specialties, d.is_verified
            FROM doctors d
            JOIN users u ON d.user_id = u.id
            WHERE u.role = 'doctor'
        `;
        
        const result = await pool.query(query);
        
        res.status(200).json(result.rows);
    } catch (error) {
        console.error("Error fetching doctors with names:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
}

// Then add this route in your routes file:
// router.get('/doctors/with-names', DoctorController.getDoctorsWithNames);
    
    
    
    
}

module.exports = DoctorController;
