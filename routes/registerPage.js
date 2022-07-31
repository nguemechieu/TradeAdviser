
const express = require('express')  ;
     
const router = express.Router() ;
router.get('/api/users/register/page',(req, res) => {
res.render('register', { title : 'Registration'})
});
module.exports = router;