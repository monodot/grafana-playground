using OpenTelemetry;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;
using Grafana.OpenTelemetry;
using Microsoft.Extensions.Logging;
using OpenTelemetry.Logs;
using Confluent.Kafka;

// Read configuration from environment variables
var bootstrapServers = Environment.GetEnvironmentVariable("KAFKA_BOOTSTRAP_SERVERS") ?? "localhost:9092";
var topic = Environment.GetEnvironmentVariable("KAFKA_TOPIC") ?? "purchases";
var groupId = Environment.GetEnvironmentVariable("KAFKA_GROUP_ID") ?? "kafka-dotnet-getting-started";
var saslUsername = Environment.GetEnvironmentVariable("KAFKA_SASL_USERNAME");
var saslPassword = Environment.GetEnvironmentVariable("KAFKA_SASL_PASSWORD");

// Kafka consumer configuration
var config = new ConsumerConfig
{
    BootstrapServers = bootstrapServers,
    GroupId          = groupId,
    AutoOffsetReset  = AutoOffsetReset.Earliest
};

// Create an instrumented consumer - this needs to be done before bootstrapping the OTel tracer provider
var instrumentedConsumerBuilder = new InstrumentedConsumerBuilder<string, string>(config);

using var tracerProvider = Sdk.CreateTracerProviderBuilder()
    .UseGrafana()
    .AddKafkaConsumerInstrumentation(instrumentedConsumerBuilder)
    .Build();
using var meterProvider = Sdk.CreateMeterProviderBuilder()
    .UseGrafana()
    .Build();
using var loggerFactory = LoggerFactory.Create(builder =>
{
    builder.AddOpenTelemetry(logging =>
    {
        logging.UseGrafana()
            .AddConsoleExporter();
    });
});

var logger = loggerFactory.CreateLogger("KafkaConsumer");


// Add SASL authentication if credentials are provided
if (!string.IsNullOrEmpty(saslUsername) && !string.IsNullOrEmpty(saslPassword))
{
    config.SaslUsername = saslUsername;
    config.SaslPassword = saslPassword;
    config.SecurityProtocol = SecurityProtocol.SaslSsl;
    config.SaslMechanism = SaslMechanism.Plain;
    logger.LogInformation("Using SASL/SSL authentication");
}
else
{
    logger.LogInformation("Using PLAINTEXT authentication (no credentials provided)");
}

CancellationTokenSource cts = new CancellationTokenSource();
Console.CancelKeyPress += (_, e) => {
    e.Cancel = true; // prevent the process from terminating.
    cts.Cancel();
};

logger.LogInformation("Starting Kafka consumer for topic: {Topic}", topic);

// Use the OTel-instrumented consumer builder that we created earlier
using (var consumer = instrumentedConsumerBuilder.Build())
{
    consumer.Subscribe(topic);
    logger.LogInformation("Subscribed to topic: {Topic}", topic);
    
    try 
    {
        while (true) 
        {
            var cr = consumer.Consume(cts.Token);
            logger.LogInformation(
                "Consumed event from topic {Topic}: key = {Key} value = {Value}",
                topic, 
                cr.Message.Key, 
                cr.Message.Value
            );
            Console.WriteLine($"Consumed event from topic {topic}: key = {cr.Message.Key,-10} value = {cr.Message.Value}");
        }
    }
    catch (OperationCanceledException) 
    {
        logger.LogInformation("Consumer cancelled (Ctrl-C pressed)");
    }
    finally
    {
        consumer.Close();
        logger.LogInformation("Consumer closed");
    }
}
