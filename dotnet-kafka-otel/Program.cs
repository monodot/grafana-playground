using OpenTelemetry;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;
using Grafana.OpenTelemetry;
using Microsoft.Extensions.Logging;
using OpenTelemetry.Logs;
using Confluent.Kafka;

using var tracerProvider = Sdk.CreateTracerProviderBuilder()
    .UseGrafana()
    .AddConsoleExporter()
    .Build();
using var meterProvider = Sdk.CreateMeterProviderBuilder()
    .UseGrafana()
    .AddConsoleExporter()
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

// Kafka consumer configuration
var config = new ConsumerConfig
{
    // User-specific properties that you must set
    BootstrapServers = "<BOOTSTRAP SERVERS>",
    SaslUsername     = "<CLUSTER API KEY>",
    SaslPassword     = "<CLUSTER API SECRET>",

    // Fixed properties
    SecurityProtocol = SecurityProtocol.SaslSsl,
    SaslMechanism    = SaslMechanism.Plain,
    GroupId          = "kafka-dotnet-getting-started",
    AutoOffsetReset  = AutoOffsetReset.Earliest
};

const string topic = "purchases";

CancellationTokenSource cts = new CancellationTokenSource();
Console.CancelKeyPress += (_, e) => {
    e.Cancel = true; // prevent the process from terminating.
    cts.Cancel();
};

logger.LogInformation("Starting Kafka consumer for topic: {Topic}", topic);

using (var consumer = new ConsumerBuilder<string, string>(config).Build())
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
