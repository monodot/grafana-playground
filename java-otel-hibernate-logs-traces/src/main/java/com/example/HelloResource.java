package com.example;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.HashMap;
import java.util.Map;

@Path("/api")
public class HelloResource {

    @GET
    @Path("/hello")
    @Produces(MediaType.APPLICATION_JSON)
    public Response hello() {
        System.out.println("GET /hello was called");
        Map<String, String> response = new HashMap<>();
        response.put("message", "Hello from JAX-RS and Undertow!");
        response.put("timestamp", String.valueOf(System.currentTimeMillis()));
        return Response.ok(response).build();
    }

    @GET
    @Path("/health")
    @Produces(MediaType.APPLICATION_JSON)
    public Response health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        return Response.ok(response).build();
    }
}
