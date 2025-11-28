using OpenTelemetry;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;
using Grafana.OpenTelemetry;
using Microsoft.Extensions.Logging;
using OpenTelemetry.Logs;

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

// See https://aka.ms/new-console-template for more information
Console.WriteLine("Hello, World!");
