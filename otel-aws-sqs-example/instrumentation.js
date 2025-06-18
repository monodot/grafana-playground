const { NodeSDK } = require('@opentelemetry/sdk-node');
const { ConsoleSpanExporter } = require('@opentelemetry/sdk-trace-node');
const {
    PeriodicExportingMetricReader,
    ConsoleMetricExporter,
} = require('@opentelemetry/sdk-metrics');
const { resourceFromAttributes } = require('@opentelemetry/resources');
const {
    ATTR_SERVICE_NAME,
    ATTR_SERVICE_VERSION,
} = require('@opentelemetry/semantic-conventions');
const {getNodeAutoInstrumentations} = require("@opentelemetry/auto-instrumentations-node");

const sdk = new NodeSDK({
    resource: resourceFromAttributes({
        [ATTR_SERVICE_NAME]: 'otel-aws-sqs-example',
        [ATTR_SERVICE_VERSION]: '0.1.0',
    }),
    traceExporter: new ConsoleSpanExporter(),
    metricReader: new PeriodicExportingMetricReader({
        exporter: new ConsoleMetricExporter(),
    }),
    // We explicitly enable just the AWS SDK auto-instrumentation here, to instrument SQS and other AWS services.
    instrumentations: [getNodeAutoInstrumentations('@opentelemetry/instrumentation-aws-sdk')],
});

sdk.start();
