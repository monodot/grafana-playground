# .NET Framework 4.8 demo

The included Dockerfile shows how to add OpenTelemetry instrumentation to a .NET Framework 4.8 app running inside a Windows container.

## Zero-code instrumentation example with HTTP headers as span attributes

**You must be on a Windows host to run this example.**

Note that the base images used in this Docker build have a combined size of around 20 GB.

Build and run the app using:

```powershell
cd cheese-app-zerocode

docker build -t cheeseapp .

docker run -e OTEL_LOG_LEVEL=debug -e OTEL_EXPORTER_OTLP_ENDPOINT="https://otlp-gateway-<REGION>.grafana.net/otlp" -e OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf -e OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic NDMyODE...wPQ==" -p 8080:80 cheeseapp
```

Now access the app at http://localhost:8080, make some requests, and you should see traces arrive in Grafana Cloud.

### Library-based instrumentation with manual span attributes

The `cheese-app-zerocode` app shows how to add library-based instrumentation and your own, custom span attributes. This is especially useful if you're not necessarily using an OpenTelemetry supported library, but you want to add some request attributes for your business.

```powershell
cd cheese-app-lib

docker build -t cheeseapp-lib .

docker run -e OTEL_LOG_LEVEL=debug -e OTEL_EXPORTER_OTLP_ENDPOINT="https://otlp-gateway-<REGION>.grafana.net/otlp" -e OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf -e OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic NDMyODE...wPQ==" -p 8080:80 cheeseapp-lib
```

Then to test the service - use a Git Bash terminal for this:

```sh
curl localhost:8080/api/values -H 'X-Store-ID: London' -XPOST -d foo=bar

curl localhost:8080/api/values -H 'X-Store-ID: Skipton' -XPOST -d foo=bar

curl localhost:8080/api/values -H 'X-Store-ID: Kuala Lumpur' -XPOST -d foo=bar
```

Or, in a loop (again, in Git Bash):

```sh
for i in {1..50}; do stores=("London" "Skipton" "Kuala Lumpur"); store=${stores[$((RANDOM % 3))]}; curl localhost:8080/api/values -H "X-Store-ID: $store" -XPOST -d foo=bar; sleep 0.1; done
```

In Grafana Traces Drilldown, you should see the attribute `cheese.store.id` attached to each span.

This project was instrumented by following the instructions at: https://opentelemetry.io/docs/languages/dotnet/netframework/, installing the packages `OpenTelemetry.Instrumentation.AspNet`, `OpenTelemetry.Exporter.Console`, `OpenTelemetry.Exporter.OpenTelemetryProtocol`.

## Troubleshooting

### OpenTelemetry debug logs

Note that in this repo, this will only work with the zero-code example.

_Environment variable: OTEL_LOG_LEVEL=debug_

By setting the optional env var `OTEL_LOG_LEVEL`, you'll see some useful debug logs in `C:\Windows\Temp`. [See example logs](./logs-windows-sample.log)

### OpenTelemetry diagnostic logs

Note that in this repo, this will only work with the zero-code example.

_Create an OTEL_DIAGNOSTICS.json file in your working directory_

To enable diagnostic logs ([see documentation](https://github.com/open-telemetry/opentelemetry-dotnet/blob/main/src/OpenTelemetry/README.md#self-diagnostics)), open a shell in the container and create the file `OTEL_DIAGNOSTICS.json`:

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

### No instrumentation happening at all?

Check that the OpenTelemetry DLL is even being loaded by your process:

```
Get-Process w3wp | Select-Object -ExpandProperty Modules
```

You should see the library in the list:

```
1304 OpenTelemetry.AutoInstrumentation.Native.dll       C:\Program Files\OpenTelemetry .NET...
```
