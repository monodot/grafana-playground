# Build stage
FROM docker.io/library/maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package

# Run stage
FROM docker.io/library/tomcat:10-jre17-temurin
WORKDIR /usr/local/tomcat/webapps/
COPY --from=build /app/target/sample-servlet.war ./ROOT.war

RUN apt update && apt install -y curl

RUN wget -O /usr/local/tomcat/opentelemetry-javaagent.jar https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.8.0/opentelemetry-javaagent.jar

#RUN echo '.level = FINE' >> /usr/local/tomcat/conf/logging.properties

EXPOSE 8080
CMD ["catalina.sh", "run"]
