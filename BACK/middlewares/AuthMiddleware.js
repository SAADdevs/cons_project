// middlewares/AuthMiddleware.js
const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
    const token = req.header('Authorization')?.split(' ')[1];  // Bearer token

    if (!token) {
        return res.status(401).json({ message: "Access Denied, Token Missing!" });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded; // Store decoded user info in request object for later use
        next();
    } catch (error) {
        console.error(error);
        res.status(401).json({ message: "Invalid Token" });
    }
};

const checkRole = (roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ message: "Access Denied: Unauthorized role" });
        }
        next();
    };
};

module.exports = { verifyToken, checkRole };
