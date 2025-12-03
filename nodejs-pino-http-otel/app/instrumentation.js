'use strict';

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');

const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');
const { OTLPLogExporter } = require('@opentelemetry/exporter-logs-otlp-http');

const { PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');
const { BatchLogRecordProcessor } = require('@opentelemetry/sdk-logs');

const {
    envDetector,
    processDetector,
    hostDetector,
    osDetector,
} = require('@opentelemetry/resources');

const { awsEcsDetector } = require('@opentelemetry/resource-detector-aws');
const { gcpDetector } = require('@opentelemetry/resource-detector-gcp');
const { containerDetector } = require('@opentelemetry/resource-detector-container');

const otlpEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318';

// OpenTelemetry SDK setup
const sdk = new NodeSDK({
    // Resource detectors
    resourceDetectors: [
        envDetector,
        processDetector,
        hostDetector,
        osDetector,
        awsEcsDetector,
        gcpDetector,
        containerDetector,
    ],

    // Traces exporter
    traceExporter: new OTLPTraceExporter({
        url: `${otlpEndpoint}/v1/traces`,
    }),

    // Metrics exporter (use metricReaders instead of metricReader)
    metricReaders: [
        new PeriodicExportingMetricReader({
            exporter: new OTLPMetricExporter({
                url: `${otlpEndpoint}/v1/metrics`,
            }),
            // adjust if you want slower/faster exports
            exportIntervalMillis: 10000,
        }),
    ],

    // Logs exporter (use logRecordProcessors instead of logRecordProcessor)
    logRecordProcessors: [
        new BatchLogRecordProcessor(
            new OTLPLogExporter({
                url: `${otlpEndpoint}/v1/logs`,
            })
        ),
    ],

    // Instrumentations
    instrumentations: [getNodeAutoInstrumentations()],
});

// Start the OpenTelemetry SDK
// Note: sdk.start() is synchronous and returns void (not a Promise)
try {
    sdk.start();

    // Now that everything is started, log confirmation
    console.log('[OTEL] OpenTelemetry SDK started (traces, metrics, logs, runtime, host metrics)');
} catch (err) {
    console.error('[OTEL] Error starting OpenTelemetry SDK', err);
}

// Graceful shutdown
let shuttingDown = false;

const shutdown = async (signal) => {
    if (shuttingDown) return;
    shuttingDown = true;

    console.log(`[OTEL] Received ${signal}, shutting down OpenTelemetry...`);

    try {
        await sdk.shutdown();
        console.log('[OTEL] OpenTelemetry SDK shut down cleanly');
        process.exit(0);
    } catch (err) {
        console.error('[OTEL] Error during OpenTelemetry shutdown', err);
        process.exit(1);
    }
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
