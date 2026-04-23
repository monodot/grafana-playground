package org.example;

import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.InetSocketAddress;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Map;
import java.util.logging.Logger;
import java.util.stream.Collectors;

public class Main {
    private static final Logger logger = Logger.getLogger(Main.class.getName());

    public static void main(String[] args) throws IOException {
        int port = 8080;
        String extractServiceUrl = System.getenv().getOrDefault("EXTRACT_SERVICE_URL", "http://extract-service:8080");

        HttpClient httpClient = HttpClient.newHttpClient();
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);

        server.createContext("/health", (HttpExchange exchange) -> {
            byte[] body = "OK".getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(200, body.length);
            try (OutputStream out = exchange.getResponseBody()) {
                out.write(body);
            }
        });

        server.createContext("/ingest", (HttpExchange exchange) -> {
            long start = System.currentTimeMillis();

            if (!"POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                exchange.sendResponseHeaders(405, -1);
                exchange.close();
                return;
            }

            String rawBody;
            try (InputStream requestBody = exchange.getRequestBody()) {
                rawBody = new String(requestBody.readAllBytes(), StandardCharsets.UTF_8);
            }

            Map<String, String> formParams = Arrays.stream(rawBody.split("&"))
                    .map(p -> p.split("=", 2))
                    .filter(p -> p.length == 2)
                    .collect(Collectors.toMap(
                            p -> URLDecoder.decode(p[0], StandardCharsets.UTF_8),
                            p -> URLDecoder.decode(p[1], StandardCharsets.UTF_8)));
            String tenant = formParams.getOrDefault("tenant", "");

            int extractStatus;
            try {
                HttpRequest extractRequest = HttpRequest.newBuilder()
                        .uri(URI.create(extractServiceUrl + "/extract"))
                        .header("Content-Type", "application/x-www-form-urlencoded")
                        .header("X-Tenant", tenant)
                        .POST(HttpRequest.BodyPublishers.ofString(rawBody, StandardCharsets.UTF_8))
                        .build();
                HttpResponse<String> extractResponse = httpClient.send(extractRequest, HttpResponse.BodyHandlers.ofString());
                extractStatus = extractResponse.statusCode();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                extractStatus = 500;
            } catch (Exception e) {
                extractStatus = 502;
            }

            int responseStatus = (extractStatus >= 200 && extractStatus < 300) ? 200
                    : (extractStatus == 502 ? 502 : 500);

            byte[] responseBody = responseStatus == 200
                    ? "OK".getBytes(StandardCharsets.UTF_8)
                    : ("Extract service failed with status " + extractStatus).getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(responseStatus, responseBody.length);
            try (OutputStream out = exchange.getResponseBody()) {
                out.write(responseBody);
            }

            long durationMs = System.currentTimeMillis() - start;
            String level = responseStatus < 400 ? "info" : "error";
            logger.info(String.format(
                    "level=%s caller=Main.java method=POST path=/ingest tenant=%s body_bytes=%d extract_status=%d duration=%dms status=%d",
                    level, tenant, rawBody.getBytes(StandardCharsets.UTF_8).length,
                    extractStatus, durationMs, responseStatus));
        });

        server.start();
        logger.info("Ingest service listening on port " + port + ", extract service URL: " + extractServiceUrl);
    }
}
