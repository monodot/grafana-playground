package com.example;

import com.example.resource.CustomerResource;
import com.example.util.HibernateUtil;
import io.undertow.Undertow;
import org.jboss.resteasy.plugins.server.undertow.UndertowJaxrsServer;
import org.jboss.resteasy.plugins.providers.jackson.ResteasyJackson2Provider;
import jakarta.ws.rs.core.Application;
import java.util.HashSet;
import java.util.Set;

public class RestApplication extends Application {

    @Override
    public Set<Class<?>> getClasses() {
        Set<Class<?>> classes = new HashSet<>();
        classes.add(HelloResource.class);
        classes.add(CustomerResource.class);
        classes.add(ResteasyJackson2Provider.class);
        return classes;
    }

    public static void main(String[] args) {
        // Initialize Hibernate
        System.out.println("Initializing Hibernate...");
        HibernateUtil.getEntityManager().close();
        System.out.println("Hibernate initialized successfully");

        // Add shutdown hook to close Hibernate
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("Shutting down Hibernate...");
            HibernateUtil.shutdown();
        }));

        UndertowJaxrsServer server = new UndertowJaxrsServer();

        Undertow.Builder builder = Undertow.builder()
                .addHttpListener(8080, "0.0.0.0");

        server.start(builder);
        server.deploy(RestApplication.class);

        System.out.println("Server started on http://localhost:8080");
        System.out.println("Try: http://localhost:8080/api/hello");
        System.out.println("Health check: http://localhost:8080/api/health");
        System.out.println("Customer endpoints:");
        System.out.println("  POST http://localhost:8080/api/customers");
        System.out.println("  GET  http://localhost:8080/api/customers");
    }
}
