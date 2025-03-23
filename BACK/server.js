const express = require('express');
const dotenv = require('dotenv');
const authRoutes = require('./routes/authRoutes');
const doctorRoutes = require('./routes/doctorRoutes');
const patientRoutes = require('./routes/patientRoutes');
const errorHandler = require('./middlewares/ErrorMiddleware');
const consultationRoutes = require('./routes/consultationRoutes');
const upcomingAppointmentsRoutes = require('./routes/upcomingAppointmentsRoutes');
const healthAdviceRoutes = require('./routes/healthAdviceRoutes');

dotenv.config();

const app = express();

// Middleware
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api', doctorRoutes); 
app.use('/api/patients', patientRoutes); // New patient routes
app.use('/api/consultations', consultationRoutes);
app.use('/api/upcoming-appointments', upcomingAppointmentsRoutes); 
app.use('/api/health-advice', healthAdviceRoutes);

// Global Error Handler
app.use(errorHandler);

// Start the server 
app.listen(5000, () => {
    console.log('Server is running on port 5000');
});