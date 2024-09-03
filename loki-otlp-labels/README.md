# Setting custom OpenTelemetry Resource Attributes to promote as labels in Loki

This Alloy config and demo app show how to set a Resource Attribute that will be promoted to a label in Loki.

Before running this, you'll need to configure your Loki/GEL distributor with an extra CLI arg, like this:

    -distributor.otlp.default_resource_attributes_as_index_labels=custom.resource.attribute

Then, edit `.env.sample` to fill in your GEL tenant ID and token.

Finally:

    podman-compose up

## How it works

In the Alloy configuration file, if you configure `otelcol.processor.batch` to send to `otelcol.exporter.debug` instead of `otelcol.exporter.otlphttp`, you'll see log resources in the console like this:

    ResourceLog #0
    Resource SchemaURL: 
    Resource attributes:
        -> custom.resource.attribute: Str(henlo_borb)
    ScopeLogs #0
    ScopeLogs SchemaURL: 
    InstrumentationScope  
    LogRecord #0
    ObservedTimestamp: 2024-09-03 18:49:55.253602546 +0000 UTC
    Timestamp: 2024-09-03 18:49:55.253347349 +0000 UTC
    SeverityText: 
    SeverityNumber: Unspecified(0)
    Body: Str(Log entry at Tue Sep  3 18:49:55 UTC 2024)
    Attributes:
        -> log.file.path: Str(/var/log/shared/app.log)
        -> log.file.name: Str(app.log)
        -> loki.attribute.labels: Str(filename,foo)
        -> filename: Str(/var/log/shared/app.log)
        -> foo: Str(fooval)
        -> custom.label: Str(label_1)
    Trace ID: 
    Span ID: 
    Flags: 0

Notice that:

- There is only **one** resource attribute, `custom.resource.attribute`.
- The remaining attributes are simply just "attributes" - these will be stored as _structured metadata_ in Loki.
