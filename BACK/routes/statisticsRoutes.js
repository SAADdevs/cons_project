// routes/statisticsRoutes.js
const express = require('express');
const router = express.Router();
const StatisticsController = require('../controllers/StatisticsController');

// Main dashboard statistics endpoint - no auth for simplicity during testing
router.get('/dashboard', StatisticsController.getDashboardStatistics);

module.exports = router;