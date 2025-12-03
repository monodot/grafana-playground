const express = require('express');
const pino = require("pino");
const app = express();
const port = 3001;

const logger = pino();

app.get('/', (req, res) => {
    logger.info('Received / request');
    res.send('Hello World!')
});

app.listen(port, () => {
    logger.info(`Example app listening on port ${port}`)
});
