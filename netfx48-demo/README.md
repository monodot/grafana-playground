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

By setting the optional env var `OTEL_LOG_LEVEL=debug`, you'll see some useful debug logs in `C:\Windows\Temp`. [See example logs](./logs-windows-sample.log)




  
