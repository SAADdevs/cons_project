// server.js
const express = require('express');
const http = require('http');
const dotenv = require('dotenv');
const cors = require('cors');
const setupSocket = require('./config/socket');

// Import routes
const authRoutes = require('./routes/authRoutes');
const doctorRoutes = require('./routes/doctorRoutes');
const patientRoutes = require('./routes/patientRoutes');
const consultationRoutes = require('./routes/consultationRoutes');
const healthAdviceRoutes = require('./routes/healthAdviceRoutes');
const chatRoutes = require('./routes/chatRoutes');
const errorHandler = require('./middlewares/ErrorMiddleware');
const statisticsRoutes = require('./routes/statisticsRoutes'); 
const upcomingAppointmentsRoutes = require('./routes/upcomingAppointmentsRoutes');
const doctorHealthAdviceRoutes = require('./routes/doctorHealthAdviceRoutes'); // Add this line

dotenv.config();

const app = express();
const server = http.createServer(app);

// Initialize Socket.IO
const io = setupSocket(server);

// Middleware
app.use(cors({
  origin: process.env.CLIENT_URL || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  credentials: true
}));
app.use(express.json());

// Make io accessible in routes
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Debug middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/doctors', doctorRoutes);
app.use('/api/patients', patientRoutes);
app.use('/api/consultations', consultationRoutes);
app.use('/api/health-advice', healthAdviceRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/doctor-advice', doctorHealthAdviceRoutes); // Add this line
app.use('/api/statistics', statisticsRoutes);
app.use('/api/upcoming-appointments', upcomingAppointmentsRoutes);


// Test route
app.get('/api/test', (req, res) => {
  res.json({ message: 'API is working!' });
});

// Error handler
app.use(errorHandler);

// Start the server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Socket.IO is initialized`);
});