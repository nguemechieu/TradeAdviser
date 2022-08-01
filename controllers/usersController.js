
const User = require('../model/User');
const db = require("../_helpers/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const Joi = require("joi");
const validateRequest = require("../middleware/validate-request");

const getAllUsers = async (req, res) => {//get all users
    const users = await db.User.find();
    if (!users) return res.status(204).json({ 'message': 'No users found' });
    res.json(users);
}

const deleteUser = async (req, res) => {//delete one user
    if (!req?.body?.id) return res.status(400).json({ "message": 'User ID required' });
    const user = await db.User.findOne({ id: req.body.id }).exec();
    if (!user) {
        return res.status(204).json({ 'message': `User ID ${req.body.id} not found` });
    }
    const result = await user.delete({ id: req.body.id });
    res.json(result);
}

const getUser = async (req, res) => {
    if (!req?.params?.id) return res.status(400).json({ "message": 'User ID required' });
    const user = await db.User.findOne({ id: req.params.id }).exec();
    if (!user) {
        return res.status(204).json({ 'message': `User ID ${req.params.id} not found` });
    }
    res.json(user);
}

let updateUser=async  (req, res) => {
    if (!req?.body?.id) {
        return res.status(400).json({ 'message': 'ID parameter is required.' });
    }

    const user = await db.User.findOne({ id: req.body.id });
    if (!user) {
        return res.status(204).json({ "message": `No user matches ID ${req.body.id}.` });
    }
    if (req.body?.firstName) user.firstName = req.body.firstName;
    if (req.body?.lastName) user.lastName = req.body.lastName;
    const result = await user.save();
    res.json(result);

};
let createNewUser=async (req, res)=>{
    // validate

    const Joi= require('joi');
    const schema = Joi.object({
        username    :   Joi.string()    .required(),
        email: Joi.string().required(),
        role: Joi.string().required(),
        password: Joi.string().required(),
        confirmPassword: Joi.string().required(),
        firstName: Joi.string().required(),
        middleName: Joi.string().required(),
        lastName: Joi.string().required(),
        country_code: Joi.string().required(),
        phone: Joi.string().required(),
    });
    validateRequest(req,res, next, schema);



    await db.User.findOne({ where: { username: req.body.username}})
        .then(async user => {
            if(!user){
                const user = new db.User(req.body);
                // hash password

                if(req.body.password!==req.body.confirmPassword){

                    return next(new Error(`Password Not Matched: ${req.body.password}`));
                }

                user.password= await bcrypt.hash(req.body.password, 10);
                user.confirmPassword= await bcrypt.hash(req.body.confirmPassword, 10);
                user.access_token=  jwt.sign(
                    { "username": user.username },
                    process.env.REFRESH_TOKEN_SECRET= user.password,
                    { expiresIn: '10s' },next
                );
                user.refreshToken=  jwt.sign(
                    { "username": user.username },
                    process.env.REFRESH_TOKEN_SECRET=user.password+1,
                    { expiresIn: '15s' },next
                );
                // save user
                const result=await user.save();
                if(result){ res.json({ message: 'New user created successfully'+user })

                }else{ res.status(404).send({    message: ' user registration failed' });}
            }
            else {
                return res.json({message: 'This username is already in used!.\nPlease choose a new one or contact nguemechieu@live.com .'})
            }
        })
        .catch(err => {  res.status(500).send({ message: err.message }) });

};
let userLogout=async (req, res) => {
    // On client, also delete the accessToken

    const cookies = req.cookies;
    if (!cookies?.jwt) return res.sendStatus(204); //No content
    const refreshToken = cookies.jwt;

    // Is refreshToken in db?
    const foundUser = await db.User.findOne({where:{ refreshToken:refreshToken }});
    if (!foundUser) {
        res.clearCookie('jwt', { httpOnly: true, sameSite: 'None', secure: true });
        return res.sendStatus(204);
    }

    // Delete refreshToken in db
    foundUser.refreshToken = foundUser.refreshToken.filter(rt => rt !== refreshToken);
    const result = await foundUser.save();
    console.log(result);

    res.clearCookie('jwt', { httpOnly: true, sameSite: 'None', secure: true });
    res.sendStatus(204);

};
let userLogin=async (req, res)=>{

    const cookies = req.cookies;
    console.log(`cookie available at login: ${JSON.stringify(cookies)}`);
    let data=  req.body;
    if (!(data.username) || !(data.password)) return res.status(400).json({ 'message': 'username and password are required.' });

    let foundUser = await db.User.findOne({where: {username: req.body.username}});
    if (!foundUser) return res.sendStatus(401); //Unauthorized
    // evaluate password
    let match;
    match =  await bcrypt.compare(data.password, foundUser.password);
    if (match) {
        const roles = foundUser.role;
        // create JWTs
        let accessToken = jwt.sign(
            {
                "User": {
                    "username": foundUser.username,
                    "role": roles
                }
            },
            process.env.ACCESS_TOKEN_SECRET="secret+11605945",
            { expiresIn: '10s' }
        );
        let newRefreshToken = jwt.sign(
            { "username": foundUser.username },
            process.env.REFRESH_TOKEN_SECRET="secret+11605945-12wd",
            { expiresIn: '1d' }
        );

        // Changed to let keyword
        let newRefreshTokenArray=(cookies.jwt)+Math.random()*(3698);

        if (cookies?.jwt) {

            /*
            Scenario added here:
                1) User logs in but never uses RT and does not logout
                2) RT is stolen
                3) If 1 & 2, reuse detection is needed to clear all RTs when user logs in
            */
            const refreshToken = cookies.jwt;
            let foundToken = await db.User.findOne({ where:    { refreshToken: refreshToken } });

            // Detected refresh token reuse!
            if (!foundToken) {
                console.log('attempted refresh token reuse at login!')
                // clear out ALL previous refresh tokens
                newRefreshTokenArray = [];
            }

            res.clearCookie('jwt', { httpOnly: true, sameSite: 'None', secure: true });
        }

        // Saving refreshToken with current user
        foundUser.refreshToken = ([newRefreshTokenArray, newRefreshToken]).toString();
        const result = await foundUser.save();
        console.log(result);
        console.log(roles);

        // Creates Secure Cookie with refresh token
        res.cookie('jwt', newRefreshToken, { httpOnly: true, secure: true, sameSite: 'None', maxAge: 24 * 60 * 60 * 1000 });

        // Send authorization roles and access token to user
        //req.setHeader['Authorization', 'Bearer ' + newRefreshToken]
        res.render('home', { roles: roles, accessToken: newRefreshToken});
        //res.json({ roles, accessToken });


    } else {
        res.sendStatus(401);
    }


};


let userResetPassword=async (req, res) =>{



    let oldPassword;

    let newPassword ;
    let confirmPassword= "";

    if(!confirmPassword)
    {
        if(oldPassword!==newPassword)
        {
            if(newPassword===confirmPassword) {
                let foundUser = await db.User.findOne({
                    where: {
                        username: req.body.username,
                        password: req.body.password
                    }
                })
                if (foundUser) {

                    foundUser.password = bcrypt.hash(req.body.confirmPassword, 10);
                    foundUser.save();//Saving new user password
                    return res.status(200).json({status: 'password updated successfully!'});
                } else return res.status(204).json({'message': 'password updated failed!'})
            }
            }


            }

};
module.exports = {
    getAllUsers,
    deleteUser,
    getUser,
    updateUser,
    createNewUser,
    userLogin,
    userLogout,
    userResetPassword

}