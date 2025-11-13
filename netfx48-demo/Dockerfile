FROM mcr.microsoft.com/dotnet/framework/sdk:4.8 AS build
WORKDIR /src

COPY CheeseApp.sln .
COPY CheeseApp.csproj . 
COPY packages.config .

RUN nuget restore CheeseApp.sln

COPY . .

RUN msbuild CheeseApp.csproj /t:WebPublish /p:WebPublishMethod=FileSystem /p:publishUrl=C:\deploy

FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019
WORKDIR /inetpub/wwwroot

COPY --from=build /deploy /inetpub/wwwroot

SHELL ["powershell", "-Command"]

ADD https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/download/v1.12.0/OpenTelemetry.DotNet.Auto.psm1 OpenTelemetry.DotNet.Auto.psm1 

RUN Import-Module .\OpenTelemetry.DotNet.Auto.psm1 ; \
    Install-OpenTelemetryCore ; \
    Register-OpenTelemetryForIIS

ENV OTEL_SERVICE_NAME=cheese-app
