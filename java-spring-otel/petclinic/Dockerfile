# Build the application first, using Maven
FROM docker.io/library/maven:3.8-eclipse-temurin-11 as build
WORKDIR /app

RUN git clone https://github.com/spring-projects/spring-petclinic
# Skipping tests just to speed things up... don't do this in production kids ⚠⛔
RUN cd spring-petclinic && mvn install -DskipTests

# --------

# Inject the JAR file into a new container to keep the file small
# Use the Eclipse community build of OpenJDK
FROM docker.io/library/eclipse-temurin:11-jre-alpine
WORKDIR /app
COPY --from=build /app/spring-petclinic/target/spring-petclinic-*.jar /app/app.jar
RUN wget -O /app/opentelemetry-javaagent.jar https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v1.18.0/opentelemetry-javaagent.jar

EXPOSE 8080
ENTRYPOINT ["sh", "-c"]
CMD ["java -jar app.jar"]
