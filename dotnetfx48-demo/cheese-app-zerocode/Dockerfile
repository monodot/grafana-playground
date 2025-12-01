FROM mcr.microsoft.com/dotnet/framework/sdk:4.8 AS build
WORKDIR /src

COPY cheese-app.sln .
COPY cheese-app.csproj . 
COPY packages.config .

RUN nuget restore cheese-app.sln

COPY . .

RUN msbuild cheese-app.csproj /t:WebPublish /p:WebPublishMethod=FileSystem /p:publishUrl=C:\deploy

FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019
WORKDIR /inetpub/wwwroot

COPY --from=build /deploy /inetpub/wwwroot

SHELL ["powershell", "-Command"]

ADD https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/download/v1.12.0/OpenTelemetry.DotNet.Auto.psm1 OpenTelemetry.DotNet.Auto.psm1 

RUN Import-Module .\OpenTelemetry.DotNet.Auto.psm1 ; \
    Install-OpenTelemetryCore ; \
    Register-OpenTelemetryForIIS

ENV OTEL_SERVICE_NAME=cheese-app-zerocode

# Optionally capture these HTTP headers and add them as span attributes
ENV OTEL_DOTNET_AUTO_TRACES_ASPNET_INSTRUMENTATION_CAPTURE_REQUEST_HEADERS=foo,SOAPAction

