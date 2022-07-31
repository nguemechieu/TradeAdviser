const express = require('express');
const router = express.Router();
router.get('/api/users/reset/password', (req, res, next) => {

    res.render('resetPassword', { title  : 'Reset Password' });
})

module.exports = router