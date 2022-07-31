
const express = require("express");
let router = express.Router();

router.route('/api/users/forgot/password').get( (req, res) => {
    res.render('forgotPassword', { title    :"Recover your account"
})})
;
module.exports = router;