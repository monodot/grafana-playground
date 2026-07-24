FROM docker.io/library/maven:3.8-eclipse-temurin-8 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -q dependency:go-offline
COPY src ./src
RUN mvn -q package

FROM docker.io/library/tomcat:9.0-jre8-temurin
ARG OTEL_AGENT_VERSION=v2.30.0
ADD https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/${OTEL_AGENT_VERSION}/opentelemetry-javaagent.jar /otel/opentelemetry-javaagent.jar
RUN chmod 444 /otel/opentelemetry-javaagent.jar
COPY --from=build /build/target/legacy-tomcat.war /usr/local/tomcat/webapps/legacy-tomcat.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
