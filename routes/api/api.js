const express = require('express');
const router=express.Router();

router.route('/api/users').get((req,res) =>{

    res.json({"start":["martial","wilfried"]});

})

module.exports = router;