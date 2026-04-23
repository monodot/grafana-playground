FROM docker.io/library/maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -q -DskipTests

FROM docker.io/library/eclipse-temurin:17-jre
WORKDIR /app
RUN curl -L https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.27.0/opentelemetry-javaagent.jar \
        -o opentelemetry-javaagent.jar
COPY --from=build /app/target/ingest-service.jar ingest-service.jar
EXPOSE 8080
ENTRYPOINT ["java", "-javaagent:opentelemetry-javaagent.jar", "-jar", "ingest-service.jar"]
