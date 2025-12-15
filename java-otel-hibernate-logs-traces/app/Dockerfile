FROM docker.io/eclipse-temurin:17-jdk-jammy AS builder

WORKDIR /app

COPY pom.xml .

RUN apt-get update && apt-get install -y maven && \
    mvn dependency:go-offline -B

COPY src ./src

RUN mvn clean package -DskipTests && \
    echo "Contents of target directory:" && \
    ls -la /app/target/ && \
    echo "Contents of target/lib (if exists):" && \
    ls -la /app/target/lib/ || echo "target/lib does not exist"

FROM docker.io/eclipse-temurin:17-jre-jammy

WORKDIR /app

COPY --from=builder /app/target/java-otel-hibernate-demo-1.0-SNAPSHOT.jar /app/app.jar
COPY --from=builder /app/target/lib /app/lib

EXPOSE 8080

CMD ["java", "-jar", "/app/app.jar"]
