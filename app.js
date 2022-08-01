
require('dotenv').config();
const express= require('express'),app=  express() , path = require('path'),

cookieParser = require('cookie-parser');
const cors = require('cors');
const corsOptions = require('./config/corsOptions');
const { logger } = require('./middleware/logEvents');
const verifyJWT = require('./middleware/verifyJWT');
const credentials = require('./middleware/credentials');
const swaggerJsDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const errorHandler = require("./middleware/errorHandler");
const bodyParser=require('body-parser');


// Initialize documentation module with SwaggerJsdoc
const swaggerOptions = {
    swaggerDefinition: {
        info: {
            title: 'TradeAdviser',
            description: "Trade Management Application ",
            contact: {
                name: "CryptoInvestor",
            },
            servers: ["https://www.tradeadviser.org"]
        }
    },

//  router: ['./routes/*.js'],
    apis: [".bin/www.js"]
}
const swaggerDocs = swaggerJsDoc(swaggerOptions);

app.use((req, res, next) => {

    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content, Accept, Content-Type, Authorization');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content, Accept, Content-Type, authorization');
    next();
});



// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'html');


// custom middleware logger
app.use(logger);

// Handle options credentials check - before CORS!
// and fetch cookies credentials requirement
app.use(credentials);

// Cross Origin Resource Sharing
app.use(cors(corsOptions));

// built-in middleware to handle urlencoded form data
app.use(express.urlencoded({ extended: false }));

// built-in middleware for json
app.use(express.json());

//middleware for cookies
app.use(cookieParser());
//##################################################

app.use(bodyParser.urlencoded({ extended: true }))
app.use(bodyParser.json({ extended: true }))

//validate requests


// Routing undefine

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', function (req, res) {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});
//app.get('/', root);
app.get('/api/users/home',require('./routes/home'))
// routes
app.use('/api/documentation', swaggerUi.serve, swaggerUi.setup(swaggerDocs))

app.get("/api/users/forgot/password" , require('./routes/forgotPassword'));
app.post('/api/users/recover/account' , require('./routes/recoverAccount.js'));
//
app.get( '/api/users/reset/password', require('./routes/resetPassword'))



app.post('/api/users/register', require('./routes/register'));
app.get('/api/users/register/page', require('./routes/registerPage'));

app.post('/api/users/auth', require('./routes/auth'));
app.get('/api/users/refresh', require('./routes/refresh'));
app.post('/api/users/logout', require('./routes/logout'));
app.use(verifyJWT);

app.get('/api/employees', require('./routes/api/employees'));
app.get('/api/users', require('./routes/api/users'));

app.use(errorHandler);
app.all('*', (req, res) => {
    res.status(404);
    if (req.accepts('ejs')) {
        res.render('404.ejs');
    } else if (req.accepts('json')) {
        res.json({ "error": "Resource requested Not Found!" });
    } else {
        res.type('txt').send("\"Resource requested Not Found!\"");
    }
});



module.exports = app;