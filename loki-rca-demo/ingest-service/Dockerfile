FROM docker.io/library/maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn package -q -DskipTests

FROM docker.io/library/eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/ingest-service.jar ingest-service.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "ingest-service.jar"]
