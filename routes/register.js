const express = require('express');
const router = express.Router();
const registerController = require('../controllers/usersController');

router.post('/api/users/register', registerController.createNewUser);

module.exports = router;