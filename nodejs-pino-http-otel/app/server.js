const express = require('express');
const pino = require("pino");
const app = express();
const port = 3001;

const logger = pino();

const logger2 = require('pino-http')();

app.get('/', (req, res) => {
    logger.info('GET /');
    logger2(req, res);
    res.send('Hello World!')
});

app.post('/', (req, res) => {
    logger.info('POST /');
    logger2(req, res);
    res.send('Thanks for the input!');
})

app.listen(port, () => {
    logger.info(`Example app listening on port ${port}`)
});
