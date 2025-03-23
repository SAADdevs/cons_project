const express = require('express');
const dotenv = require('dotenv');
const authRoutes = require('./routes/authRoutes');
const doctorRoutes = require('./routes/doctorRoutes');
const patientRoutes = require('./routes/patientRoutes');
const errorHandler = require('./middlewares/ErrorMiddleware');
const consultationRoutes = require('./routes/consultationRoutes');
const upcomingAppointmentsRoutes = require('./routes/upcomingAppointmentsRoutes');
const healthAdviceRoutes = require('./routes/healthAdviceRoutes');
const statisticsRoutes = require('./routes/statisticsRoutes'); // Import statistics routes

dotenv.config();

const app = express();

// Middleware
app.use(express.json());

// CORS middleware for development
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api', doctorRoutes); 
app.use('/api/patients', patientRoutes);
app.use('/api/consultations', consultationRoutes);
app.use('/api/upcoming-appointments', upcomingAppointmentsRoutes); 
app.use('/api/health-advice', healthAdviceRoutes);
app.use('/api/statistics', statisticsRoutes); // Add the statistics routes

// Global Error Handler
app.use(errorHandler);

// Start the server 
app.listen(5000, () => {
    console.log('Server is running on port 5000');
});