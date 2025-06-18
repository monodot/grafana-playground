# OpenTelemetry AWS SQS Example

Example of configuring the OpenTelemetry `aws-sdk` Instrumentation for Node.js, to add trace context to SQS messages.

```sh
aws configure export-credentials --profile <your-sso-profile-name> --format env > .env

source .env

npm run dev

export SQS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/000000000000/your-queue-name
curl localhost:8080/send
```
