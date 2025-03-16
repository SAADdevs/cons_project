// middlewares/ValidationMiddleware.js

const validateRegisterInput = (req, res, next) => {
    const { full_name, email, password, role } = req.body;
    
    if (!full_name || !email || !password || !role) {
        return res.status(400).json({ message: "Missing required fields" });
    }

    // Validate email format
    const emailRegex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
    if (!emailRegex.test(email)) {
        return res.status(400).json({ message: "Invalid email format" });
    }

    // Validate password length
    if (password.length < 6) {
        return res.status(400).json({ message: "Password must be at least 6 characters long" });
    }

    next();
};

module.exports = { validateRegisterInput };
