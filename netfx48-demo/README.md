# .NET Framework 4.8 demo

Instrumenting a .NET Framework 4.8 app with OpenTelemetry.

## Running the example

**You must be on a Windows host to run this example.**

Build and run the app using:

```powershell
docker build -t cheeseapp .

docker run -e OTEL_EXPORTER_OTLP_ENDPOINT="https://otlp-gateway-<REGION>.grafana.net/otlp" -e OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf -e OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic NDMyODE...wPQ==" -p 8080:80 cheeseapp
```

## Useful information

### OpenTelemetry debug logs

You'll see some useful debug logs in `C:\Windows\Temp`. [See example logs](./logs-windows-temp.log)

  
