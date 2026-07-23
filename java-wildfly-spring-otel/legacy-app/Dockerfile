FROM docker.io/library/maven:3.8-eclipse-temurin-8 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -q dependency:go-offline
COPY src ./src
RUN mvn -q package

FROM docker.io/library/eclipse-temurin:8-jdk
ARG WILDFLY_VERSION=26.1.3.Final
ARG OTEL_AGENT_VERSION=v2.30.0
RUN apt-get update && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/wildfly.zip \
      https://github.com/wildfly/wildfly/releases/download/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.zip \
    && unzip -q /tmp/wildfly.zip -d /opt \
    && mv /opt/wildfly-${WILDFLY_VERSION} /opt/wildfly \
    && rm /tmp/wildfly.zip
ADD https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/${OTEL_AGENT_VERSION}/opentelemetry-javaagent.jar /otel/opentelemetry-javaagent.jar
RUN chmod 444 /otel/opentelemetry-javaagent.jar
COPY --from=build /build/target/legacy-app.war /opt/wildfly/standalone/deployments/
EXPOSE 8080
CMD ["/opt/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]
