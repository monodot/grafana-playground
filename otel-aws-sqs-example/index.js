const {SQSClient, SendMessageCommand} = require('@aws-sdk/client-sqs');
const express = require('express');
const opentelemetry = require('@opentelemetry/api');

const PORT = parseInt(process.env.PORT || '8080');
const AWS_REGION = process.env.AWS_REGION || "us-east-1"; // Change to your desired AWS region
const QUEUE_URL = process.env.SQS_QUEUE_URL;

if (!QUEUE_URL) {
    console.error('SQS_QUEUE_URL environment variable is required');
    process.exit(1);
}

const app = express();
app.use(express.urlencoded({extended: false}));

const sqsClient = new SQSClient({region: AWS_REGION});

const tracer = opentelemetry.trace.getTracer(
    'otel-aws-sqs-example'
);

app.post('/send', async (req, res) => {
    return tracer.startActiveSpan('POST /send', async (span) => {
        const message = req.body.message || 'Default message body';
        const command = new SendMessageCommand({
            QueueUrl: QUEUE_URL,
            MessageBody: message,
            MessageAttributes: {
                'source': {
                    DataType: 'String',
                    StringValue: 'otel-aws-sqs-example'
                },
            }
        });

        const result = await sqsClient.send(command);
        console.log(`Message sent to SQS: ${message}, MessageId: ${result.MessageId}`);
        span.end();
        res.status(200).send("Done things!");
    });

});

app.listen(PORT, () => {
    console.log(`Listening for requests on http://localhost:${PORT}`);
});
