const express = require('express');
const dotenv = require('dotenv');
const authRoutes = require('./routes/authRoutes');
const doctorRoutes = require('./routes/doctorRoutes'); // Add this line
const errorHandler = require('./middlewares/ErrorMiddleware');
const consultationRoutes = require('./routes/consultationRoutes');


dotenv.config();

const app = express();

// Middleware
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api', doctorRoutes); 
app.use('/api/consultations', consultationRoutes);
// Global Error Handler
app.use(errorHandler);

// Start the server 
app.listen(5000, () => {
    console.log('Server is running on port 5000');
});
