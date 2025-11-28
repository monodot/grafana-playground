// This is shared between the requester, the recorder and the server
// As such, to only do what's needed, we init using a
// function and then pass the service context to
// determine what to initialise.
const {registerInstrumentations} = require("@opentelemetry/instrumentation");
const {getNodeAutoInstrumentations} = require("@opentelemetry/auto-instrumentations-node");
const {AwsInstrumentation} = require("@opentelemetry/instrumentation-aws-sdk");

registerInstrumentations({
    instrumentations: [
        getNodeAutoInstrumentations(),
        // new AwsInstrumentation() // For instrumenting AWS SDK calls (e.g., SQS)
    ],
});

module.exports = (context, serviceName) => {
    // Include all OpenTelemetry dependencies for tracing
    const api = require("@opentelemetry/api");
    const { NodeTracerProvider } = require("@opentelemetry/sdk-trace-node");
    const { SimpleSpanProcessor } = require("@opentelemetry/sdk-trace-base");
    const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
    const { defaultResource, detectResources, resourceFromAttributes, envDetector, processDetector, osDetector } = require('@opentelemetry/resources');
    const { awsEcsDetector } = require('@opentelemetry/resource-detector-aws');
    const { ATTR_SERVICE_NAME } = require('@opentelemetry/semantic-conventions');
    const { registerInstrumentations } = require('@opentelemetry/instrumentation');
    const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
    const { AwsInstrumentation } = require('@opentelemetry/instrumentation-aws-sdk');

    return async () => {
        console.log('OTEL Environment Variables:');
        console.log('OTEL_TRACES_EXPORTER:', process.env.OTEL_TRACES_EXPORTER);
        console.log('OTEL_RESOURCE_ATTRIBUTES:', process.env.OTEL_RESOURCE_ATTRIBUTES);
        console.log('OTEL_EXPORTER_OTLP_TRACES_INSECURE:', process.env.OTEL_EXPORTER_OTLP_TRACES_INSECURE);

        let W3CTraceContextPropagator;
        if (context === 'requester') {
            W3CTraceContextPropagator = require("@opentelemetry/core").W3CTraceContextPropagator;
        }

        // Detect resources and then merge with the service name
        const detected = await detectResources({
            detectors: [envDetector, processDetector, osDetector, awsEcsDetector ]
        });

        const resources = defaultResource() // sets telemetry.sdk.name, version, language
            .merge(resourceFromAttributes({
                [ATTR_SERVICE_NAME]: serviceName,
            }))
            .merge(detected);

        // Export via OTLP gRPC
        const exporter = new OTLPTraceExporter({
            url: `${process.env.TRACING_COLLECTOR_HOST || 'localhost'}:${process.env.TRACING_COLLECTOR_PORT || '4317'}`
        });

        console.log('Merged resource attributes:', resources.attributes);

        // Use simple span processor (for production code without memory pressure, you should probably use Batch)
        const processor = new SimpleSpanProcessor(exporter);

        // Create a tracer provider
        const provider = new NodeTracerProvider({
            resource: resources,
            spanProcessors: [processor],
        });
        provider.register();

        // Create a new header for propagation from a given span
        let createPropagationHeader;
        if (context === 'requester') {
            const propagator = new W3CTraceContextPropagator();
            createPropagationHeader = (span) => {
                let carrier = {};
                // Inject the current trace context into the carrier object
                propagator.inject(
                    api.trace.setSpanContext(api.ROOT_CONTEXT, span.spanContext()),
                    carrier,
                    api.defaultTextMapSetter
                );
                return carrier;
            };
        }

        // registerInstrumentations({
        //     instrumentations: [
        //         getNodeAutoInstrumentations(),
        //         new AwsInstrumentation() // For instrumenting AWS SDK calls (e.g., SQS)
        //     ],
        // });

        // Return instances of the API and the tracer to the calling app
        return {
            tracer: api.trace.getTracer(serviceName),
            api: api,
            propagator: createPropagationHeader,
        }
    };
};
