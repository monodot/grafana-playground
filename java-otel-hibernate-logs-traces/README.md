# Java (Hibernate): Capturing DB Statements as OTLP Logs and Traces with OpenTelemetry

A simple Java REST API using JAX-RS and Undertow.

## Prerequisites

- Java 17 or higher
- Maven 3.6+

## Building and Running

### With Maven

Build the application:

```bash
mvn clean package
```

Run the application:

```bash
java -jar target/java-otel-hibernate-demo-1.0-SNAPSHOT.jar
```

Or run directly with Maven:

```bash
mvn compile exec:java -Dexec.mainClass="com.example.RestApplication"
```

### With Docker/Podman

Build the image:

```bash
podman build -t java-otel-demo .
```

Run the container:

```bash
podman run -p 8080:8080 java-otel-demo
```

## Testing the API

The server starts on http://localhost:8080

Test the hello endpoint:

```bash
curl http://localhost:8080/api/hello
```

Check the health endpoint:

```bash
curl http://localhost:8080/api/health
```

## Project Structure

- `src/main/java/com/example/RestApplication.java` - Main application class that starts Undertow server
- `src/main/java/com/example/HelloResource.java` - JAX-RS resource with REST endpoints
- `pom.xml` - Maven configuration with dependencies
- `Dockerfile` - Multi-stage build using Eclipse Temurin JDK and JRE

