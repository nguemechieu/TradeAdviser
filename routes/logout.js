const express = require('express');
const router = express.Router();
const logoutController = require('../controllers/usersController');
const verifyJWT = require("../middleware/verifyJWT");

router.post('/api/users/logout', verifyJWT,logoutController.userLogout);

module.exports = router;