FROM mcr.microsoft.com/dotnet/framework/sdk:4.8 AS build
WORKDIR /src

COPY cheese-app.sln .
COPY cheese-app.csproj . 
COPY packages.config .

RUN nuget restore cheese-app.sln

COPY . .
COPY Global.asax.cs .

RUN msbuild cheese-app.csproj /t:WebPublish /p:WebPublishMethod=FileSystem /p:publishUrl=C:\deploy

FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019
WORKDIR /inetpub/wwwroot

COPY --from=build /deploy /inetpub/wwwroot

SHELL ["powershell", "-Command"]
