# Java (Hibernate): Capturing DB Statements as OTLP Logs and Traces with OpenTelemetry

A simple Java REST API using JAX-RS, Undertow, and Hibernate with an H2 in-memory database.

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

Or with explicit classpath:

```bash
java -cp "target/lib/*:target/java-otel-hibernate-demo-1.0-SNAPSHOT.jar" com.example.RestApplication
```

Or run directly with Maven:

```bash
mvn compile exec:java
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

### Basic Endpoints

Test the hello endpoint:

```bash
curl http://localhost:8080/api/hello
```

Check the health endpoint:

```bash
curl http://localhost:8080/api/health
```

### Customer Endpoints

Create a customer with JSON:

```bash
curl -X POST http://localhost:8080/api/customers \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'
```

Create a customer with form data:

```bash
curl -X POST http://localhost:8080/api/customers \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=Jane Doe&email=jane@example.com"
```

Or simply:

```bash
curl -X POST http://localhost:8080/api/customers \
  -d "name=Bob Smith&email=bob@example.com"
```

List all customers:

```bash
curl http://localhost:8080/api/customers
```

## Project Structure

- `src/main/java/com/example/RestApplication.java` - Main application class that starts Undertow server
- `src/main/java/com/example/HelloResource.java` - JAX-RS resource with REST endpoints
- `src/main/java/com/example/resource/CustomerResource.java` - Customer REST API endpoints
- `src/main/java/com/example/entity/Customer.java` - JPA entity for customer data
- `src/main/java/com/example/util/HibernateUtil.java` - Hibernate EntityManager factory utility
- `src/main/resources/META-INF/persistence.xml` - JPA/Hibernate configuration
- `pom.xml` - Maven configuration with dependencies (Hibernate, H2, RESTEasy)
- `Dockerfile` - Multi-stage build using Eclipse Temurin JDK and JRE

## Features

- **REST API**: JAX-RS (RESTEasy) endpoints for CRUD operations
- **Database**: H2 in-memory database with Hibernate ORM
- **Dual Content-Type Support**: Accepts both JSON and form-urlencoded data
- **Auto Schema Generation**: Hibernate creates database schema from JPA entities

