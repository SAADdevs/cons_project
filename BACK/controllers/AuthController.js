const User = require('../Models/User');
const Doctor = require('../Models/Doctor');
const Patient = require('../Models/Patient');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken'); 
const pool = require('../config/db');


class AuthController {
    // Register a new user
    static async registerUser(req, res) {
        console.log("i am inside register user");
        const { full_name, email, password, role, IMPE, specialties, hospital, age, gender } = req.body;
        
        try {
            // Check if email already exists
            const userExists = await User.getUserByEmail(email);
            if (userExists) {
                return res.status(400).json({ message: "Email already in use" });
            }
            
            const hashedPassword = await bcrypt.hash(password, 10);
            
            const newUser = await User.createUser({ 
                full_name, 
                email, 
                password: hashedPassword, 
                role 
            });
            
            if (role === 'doctor') {
                await Doctor.createDoctor(newUser.id, IMPE, specialties, hospital);
            } else if (role === 'patient') {
                // Create patient record if role is patient
                if (!age || !gender) {
                    return res.status(400).json({ message: "Age and Gender are required for patients" });
                }
                await Patient.c(newUser.id, age, gender); // Passing age and gender
            }
            
            res.status(201).json({ 
                message: "User registered successfully", 
                user: {
                    id: newUser.id,
                    full_name: newUser.full_name,
                    email: newUser.email,
                    role: newUser.role
                }
            });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }
    
    // In your AuthController.js - loginUser function
static async loginUser(req, res) {
    const { email, password } = req.body;
    
    try {
        const user = await User.getUserByEmail(email);
        if (!user) {
            return res.status(401).json({ message: "Invalid credentials" });
        }
        
        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({ message: "Invalid credentials" });
        }
        
        // Debug - log the role to see what's happening
        console.log("User role from database:", user.role);
        
        // Generate JWT token with role included
        const token = jwt.sign(
            { id: user.id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );
        
        res.json({ 
            message: "Login successful", 
            token, 
            user: {
                id: user.id,
                full_name: user.full_name,
                email: user.email,
                role: user.role  // Make sure role is included here
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error" });
    }
}    static async getUserProfile(req, res) {
        try {
            const userId = req.user.id;
            const user = await User.getUserById(userId);
            
            if (!user) {
                return res.status(404).json({ message: "User not found" });
            }
            
            // Don't send password in response
            const { password, ...userWithoutPassword } = user;
            
            res.json({ user: userWithoutPassword });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }

    static async updateUserProfile(req, res) {
        try {
            const userId = req.user.id; // From the authentication middleware
            const { full_name, email } = req.body;
            
            console.log(`Updating user profile for user_id ${userId}: Full Name: ${full_name}, Email: ${email}`);
            
            // Check if email is already in use by another user
            if (email) {
                const existingUser = await User.getUserByEmail(email);
                if (existingUser && existingUser.id !== userId) {
                    return res.status(400).json({ message: "Email already in use" });
                }
            }
            
            const updatedUser = await User.updateUser(userId, { full_name, email });
            
            res.json({ 
                message: "Profile updated successfully", 
                user: {
                    id: updatedUser.id,
                    full_name: updatedUser.full_name,
                    email: updatedUser.email,
                    role: updatedUser.role
                }
            });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }

    static async changePassword(req, res) {
        const userId = req.user.id;
        const { currentPassword, newPassword } = req.body;
        
        try {
            const user = await User.getUserById(userId);
            
            const validPassword = await bcrypt.compare(currentPassword, user.password);
            if (!validPassword) {
                return res.status(401).json({ message: "Current password is incorrect" });
            }
            
            const hashedPassword = await bcrypt.hash(newPassword, 10);
            await User.updatePassword(userId, hashedPassword);
            
            res.json({ message: "Password updated successfully" });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }

    static async getAuthUserId(req, res) {
        try {
            if (!req.user) {
                return res.status(401).json({ message: 'User not authenticated' });
            }

            const userId = req.user.id;
            res.status(200).json({ userId });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server error' });
        }
    }
    static async registerUser(req, res) {
        console.log("Inside register user function");
        const { full_name, email, password, role, IMPE, specialties, hospital, age, gender } = req.body;
        
        try {
            // Check if email already exists
            const userExists = await User.getUserByEmail(email);
            if (userExists) {
                return res.status(400).json({ message: "Email already in use" });
            }
            
            const hashedPassword = await bcrypt.hash(password, 10);
            
            const newUser = await User.createUser({ 
                full_name, 
                email, 
                password: hashedPassword, 
                role 
            });
            
            if (role === 'doctor') {
                await Doctor.createDoctor(newUser.id, IMPE, specialties, hospital);
            } else if (role === 'patient') {
                // Create patient record if role is patient
                if (!age || !gender) {
                    return res.status(400).json({ message: "Age and Gender are required for patients" });
                }
                await Patient.createPatient(newUser.id, age, gender); // Passing age and gender
            }
            
            res.status(201).json({ 
                message: "User registered successfully", 
                user: {
                    id: newUser.id,
                    full_name: newUser.full_name,
                    email: newUser.email,
                    role: newUser.role
                }
            });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error", error: error.message });
        }
    }
    
    // In your AuthController.js - loginUser function
    static async loginUser(req, res) {
        const { email, password } = req.body;
        
        try {
            const user = await User.getUserByEmail(email);
            if (!user) {
                return res.status(401).json({ message: "Invalid credentials" });
            }
            
            const validPassword = await bcrypt.compare(password, user.password);
            if (!validPassword) {
                return res.status(401).json({ message: "Invalid credentials" });
            }
            
            // Debug - log the role to see what's happening
            console.log("User role from database:", user.role);
            
            // Generate JWT token with role included
            const token = jwt.sign(
                { id: user.id, role: user.role },
                process.env.JWT_SECRET,
                { expiresIn: '7d' }
            );
            
            res.json({ 
                message: "Login successful", 
                token, 
                user: {
                    id: user.id,
                    full_name: user.full_name,
                    email: user.email,
                    role: user.role  // Make sure role is included here
                }
            });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }
    
    static async getUserProfile(req, res) {
        try {
            const userId = req.user.id;
            const user = await User.getUserById(userId);
            
            if (!user) {
                return res.status(404).json({ message: "User not found" });
            }
            
            // Don't send password in response
            const { password, ...userWithoutPassword } = user;
            
            res.json({ user: userWithoutPassword });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }

    static async updateUserProfile(req, res) {
        try {
            const userId = req.user.id; // From the authentication middleware
            const { full_name, email } = req.body;
            
            console.log(`Updating user profile for user_id ${userId}: Full Name: ${full_name}, Email: ${email}`);
            
            // Check if email is already in use by another user
            if (email) {
                const existingUser = await User.getUserByEmail(email);
                if (existingUser && existingUser.id !== userId) {
                    return res.status(400).json({ message: "Email already in use" });
                }
            }
            
            const updatedUser = await User.updateUser(userId, { full_name, email });
            
            res.json({ 
                message: "Profile updated successfully", 
                user: {
                    id: updatedUser.id,
                    full_name: updatedUser.full_name,
                    email: updatedUser.email,
                    role: updatedUser.role
                }
            });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }

    static async changePassword(req, res) {
        const userId = req.user.id;
        const { currentPassword, newPassword } = req.body;
        
        try {
            const user = await User.getUserById(userId);
            
            const validPassword = await bcrypt.compare(currentPassword, user.password);
            if (!validPassword) {
                return res.status(401).json({ message: "Current password is incorrect" });
            }
            
            const hashedPassword = await bcrypt.hash(newPassword, 10);
            await User.updatePassword(userId, hashedPassword);
            
            res.json({ message: "Password updated successfully" });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Add this method to your AuthController.js or create a separate method

static async getCurrentUser(req, res) {
    try {
        // Check if user is set by middleware
        if (!req.user || !req.user.id) {
            console.error('User not set in request:', req.user);
            return res.status(401).json({ message: 'Not authenticated. Please login again.' });
        }
        
        const userId = req.user.id;
        console.log('Getting profile for user ID:', userId);
        
        // Query to get basic user info
        const userQuery = await pool.query(
            'SELECT id, full_name, email, role, created_at FROM users WHERE id = $1',
            [userId]
        );
        
        if (userQuery.rows.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        const user = userQuery.rows[0];
        console.log('Found user:', user);
        
        // Depending on the role, get the professional ID (doctor_id or patient_id)
        if (user.role === 'doctor') {
            const doctorQuery = await pool.query(
                'SELECT id, specialties, hospital, is_available, is_verified FROM doctors WHERE user_id = $1',
                [userId]
            );
            
            if (doctorQuery.rows.length > 0) {
                user.doctor_id = doctorQuery.rows[0].id;
                user.specialties = doctorQuery.rows[0].specialties;
                user.hospital = doctorQuery.rows[0].hospital;
                user.is_available = doctorQuery.rows[0].is_available;
                user.is_verified = doctorQuery.rows[0].is_verified;
            }
        } else if (user.role === 'patient') {
            const patientQuery = await pool.query(
                'SELECT id, age, gender FROM patients WHERE user_id = $1',
                [userId]
            );
            
            if (patientQuery.rows.length > 0) {
                user.patient_id = patientQuery.rows[0].id;
                user.age = patientQuery.rows[0].age;
                user.gender = patientQuery.rows[0].gender;
            }
        }
        
        // Remove sensitive data
        delete user.password;
        
        return res.status(200).json(user);
    } catch (error) {
        console.error('Error getting current user:', error);
        return res.status(500).json({
            message: 'Error retrieving user profile',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
}

    static async getAuthUserId(req, res) {
        try {
            if (!req.user) {
                return res.status(401).json({ message: 'User not authenticated' });
            }

            const userId = req.user.id;
            res.status(200).json({ userId });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server error' });
        }
    }
}

module.exports = AuthController;