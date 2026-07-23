FROM docker.io/library/maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -q dependency:go-offline
COPY src ./src
RUN mvn -q package -DskipTests

FROM docker.io/library/eclipse-temurin:17-jre
ARG OTEL_AGENT_VERSION=v2.30.0
ARG PYROSCOPE_AGENT_VERSION=v2.8.0
ARG PYROSCOPE_OTEL_VERSION=v2.1.0
ADD https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/${OTEL_AGENT_VERSION}/opentelemetry-javaagent.jar /otel/opentelemetry-javaagent.jar
ADD https://github.com/grafana/pyroscope-java/releases/download/${PYROSCOPE_AGENT_VERSION}/pyroscope.jar /otel/pyroscope.jar
ADD https://github.com/grafana/otel-profiling-java/releases/download/${PYROSCOPE_OTEL_VERSION}/pyroscope-otel-javaagent-extension.jar /otel/pyroscope-otel.jar
COPY --from=build /build/target/gateway-api-1.0.0.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
