
const express = require('express');
const verifyJWT = require("../middleware/verifyJWT");


const router = express.Router();

router.post('/api/users/home/',verifyJWT,(req, res,next) => {


    res.render('home.ejs', { title  : 'Home' });
});

module.exports = router;