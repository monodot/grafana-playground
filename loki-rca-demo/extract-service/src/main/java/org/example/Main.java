package org.example;

import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ThreadLocalRandom;
import java.util.logging.Logger;

public class Main {
    private static final Logger logger = Logger.getLogger(Main.class.getName());

    public static void main(String[] args) throws IOException {
        int port = 8080;
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);

        server.createContext("/extract", (HttpExchange exchange) -> {
            long start = System.currentTimeMillis();

            if (!"POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                exchange.sendResponseHeaders(405, -1);
                exchange.close();
                return;
            }

            String tenant = exchange.getRequestHeaders().getFirst("X-Tenant");
            if (tenant == null) tenant = "";

            String body;
            try (InputStream requestBody = exchange.getRequestBody()) {
                body = new String(requestBody.readAllBytes(), StandardCharsets.UTF_8);
            }

            try {
                long delay = ThreadLocalRandom.current().nextLong(30, 501);
                Thread.sleep(delay);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }

            byte[] response = "OK".getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(200, response.length);
            try (OutputStream out = exchange.getResponseBody()) {
                out.write(response);
            }

            long durationMs = System.currentTimeMillis() - start;
            logger.info(String.format(
                    "level=info caller=Main.java method=POST path=/extract tenant=%s body_bytes=%d duration=%dms status=200",
                    tenant, body.getBytes(StandardCharsets.UTF_8).length, durationMs));
        });

        server.start();
        logger.info("Extract service listening on port " + port);
    }
}
