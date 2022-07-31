const express = require('express');
const router = express.Router();
const usersController = require('../../controllers/usersController');
const ROLES_LIST = require('../../config/roles_list');
const verifyRoles = require('../../middleware/verifyRoles');

router.route('/api/users/admin')


    .get(usersController.getAllUsers)
    .post(verifyRoles(ROLES_LIST.admin, ROLES_LIST.editor), usersController.createNewUser)
    .put(verifyRoles(ROLES_LIST.admin, ROLES_LIST.editor), usersController.updateUser)
    .delete(verifyRoles(ROLES_LIST.admin), usersController.deleteUser);

module.exports = router;