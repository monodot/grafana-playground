FROM docker.io/eclipse-temurin:17-jdk-jammy AS builder

WORKDIR /app

COPY pom.xml .

RUN apt-get update && apt-get install -y maven && \
    mvn dependency:go-offline -B

COPY src ./src

RUN mvn clean package -DskipTests

FROM docker.io/eclipse-temurin:17-jre-jammy

RUN wget -O /usr/local/opentelemetry-javaagent.jar https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.23.0/opentelemetry-javaagent.jar

WORKDIR /app

COPY --from=builder /app/target/java-otel-hibernate-demo-1.0-SNAPSHOT.jar /app/app.jar
COPY --from=builder /app/target/lib /app/lib

EXPOSE 8080

CMD ["java", "-jar", "/app/app.jar"]
