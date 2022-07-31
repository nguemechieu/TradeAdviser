let transport = require('nodemailer');
const express = require('express');
const db = require("../_helpers/db");
const router = express.Router();



router.post('/api/users/recover/account',async (req, res) => {


    const transporter = transport.createTransport({
        service: "gmail.com",
        auth: {
            user: 'noelmartialnguemechieu',
            pass: 'lacsnulyigwcwkso',
        },
    })

    let user= req.body;
    const found = await db.User.findOne({ where:{email:user.email}})

        if(!found) {  return res.send({result: 'User email not found!'})}

        else if(found) {

            try {
                let pass = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'v', '-', 'x', '+', 'z', '/', '=', '2', '3', '4', '5', '6', '#', '@', '$', ',', ':'];

                let aa, bb, cc, dd, ee, ff;
                let i = Math.floor(Math.random() * 40),
                    a = Math.floor(Math.random() * 40),
                    b = Math.floor(Math.random() * 40),
                    e = Math.floor(Math.random() * 40);

                aa = pass[e];
                bb = pass[a];
                cc = pass[i];
                dd = pass[b];
                ee = pass[e];
                ff = pass[i];
                const resetPass = 10 + "c" + ff + aa + bb + cc + dd + 34 + ee;
                const email = user.email;
                const mailOptions = {
                    from: "nnoelmartial@yahoo.fr",
                    to: email,
                    subject: "Reset Password Code",
                    text: {"======> CryptoInvestor <=======\n " :
                            "   Hi there, <=======\n Here is your new password valid for only 2 hours!\nPlease make sure you update your password.\n\nYour new password is!\n  " + resetPass,
                }
                }

                await transporter.sendMail(mailOptions, function (error, info) {
                    if (error) {
                        console.log(error)
                    } else {
                        console.log("Sent: Reset Password Code sent successfully")
                        return res.send("Reset Password Code sent successfully")
                    }
                });
            } catch (err) {
                console.log(err)
            }//return errorHandler

        }else{
           return  res.status(403).send({ error: error+" status: " + error.status || 204,message:"Try different email !"});
           // await res.redirect('/api/users/forgot/password')
        }
 })
 module.exports = router;