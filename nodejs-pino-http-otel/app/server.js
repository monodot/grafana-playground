const express = require('express');
const pino = require("pino");
const app = express();
const port = 3001;

const logger = pino();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const logger2 = require('pino-http')({});

app.use(logger2); // Installs pino-http as a middleware in Express.js - https://expressjs.com/en/guide/using-middleware.html

app.get('/', (req, res) => {
    logger.info('GET /');
    res.send('Hello World!')
});

app.post('/', (req, res) => {
    logger.info('POST /');
    res.send('Thanks for the input!');
})

app.listen(port, () => {
    logger.info(`Example app listening on port ${port}`)
});
