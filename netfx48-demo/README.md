# .NET Framework 4.8 demo

The included Dockerfile shows how to add OpenTelemetry instrumentation to a .NET Framework 4.8 app running inside a Windows container.

## Running the example

**You must be on a Windows host to run this example.**

Note that the base images used in this Docker build have a combined size of around 20 GB.

Build and run the app using:

```powershell
docker build -t cheeseapp .

docker run -e OTEL_LOG_LEVEL=debug -e OTEL_EXPORTER_OTLP_ENDPOINT="https://otlp-gateway-<REGION>.grafana.net/otlp" -e OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf -e OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic NDMyODE...wPQ==" -p 8080:80 cheeseapp
```

## Useful information

### OpenTelemetry debug logs

Environment variable **OTEL_LOG_LEVEL=debug**

By setting the optional env var `OTEL_LOG_LEVEL`, you'll see some useful debug logs in `C:\Windows\Temp`. [See example logs](./logs-windows-sample.log)

### OpenTelemetry Diagnostic Logs

As per: https://github.com/open-telemetry/opentelemetry-dotnet/blob/main/src/OpenTelemetry/README.md#self-diagnostics

To enable Diagnostic logs, open a shell in the container and create the file `OTEL_DIAGNOSTICS.json`:

```powershell
$jsonContent = @"
{
    "LogDirectory": "C:\Windows\Temp",
    "FileSize": 32768,
    "LogLevel": "Warning",
    "FormatMessage": "true"
}
"@

Set-Content -Path "C:\Windows\System32\inetsrv\OTEL_DIAGNOSTICS.json" -Value $jsonContent
```

After a few seconds you should see a file in `C:\Windows\Temp` like `w3wp.exe.1328.log`. It writes lines like this:

```
If you are seeing this message, it means that the OpenTelemetry SDK has successfully created the log file used to write
self-diagnostic logs. This file will be appended with logs as they appear. If you do not see any logs following this lin
e, it means no logs of the configured LogLevel is occurring. You may change the LogLevel to show lower log levels, so th
at logs of lower severities will be shown.
2025-11-13T18:46:15.0492550Z:Failed to inject activity context in format: '{0}', context: '{1}'.{TraceContextPropagator}
{Invalid context}
2025-11-13T18:47:15.0425619Z:Failed to inject activity context in format: '{0}', context: '{1}'.{TraceContextPropagator}
{Invalid context}
```
