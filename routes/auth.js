const express = require('express');
const router = express.Router();
const authController = require('../controllers/usersController');

router.post('/api/users/auth', authController.userLogin);

module.exports = router;