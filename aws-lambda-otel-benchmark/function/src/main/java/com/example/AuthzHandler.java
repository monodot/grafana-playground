package com.example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.Map;

/**
 * Mock JWT-validation function that simulates ~25 ms of real authz work.
 *
 * All 11 benchmark configurations use this same JAR. Instrumentation is
 * controlled entirely via environment variables and Lambda layers — no code
 * changes needed between configs.
 */
public class AuthzHandler implements RequestHandler<APIGatewayV2HTTPEvent, APIGatewayV2HTTPResponse> {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    // Set to false after the first invocation; lets k6 detect cold starts from
    // the response body without needing CloudWatch access during the test run.
    private static volatile boolean coldStart = true;

    @Override
    public APIGatewayV2HTTPResponse handleRequest(APIGatewayV2HTTPEvent event, Context context) {
        boolean isColdStart = coldStart;
        coldStart = false;

        long startMs = System.currentTimeMillis();

        String token = extractToken(event.getBody());
        boolean authorized = validateToken(token);
        String subject = extractSubject(token);

        // Pad to ~25 ms to simulate consistent authz latency regardless of how
        // quickly the crypto work finishes on a given instance type / memory tier.
        long elapsed = System.currentTimeMillis() - startMs;
        if (elapsed < 25) {
            try {
                Thread.sleep(25 - elapsed);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }

        long totalMs = System.currentTimeMillis() - startMs;

        ObjectNode body = MAPPER.createObjectNode()
                .put("authorized", authorized)
                .put("subject", subject)
                .put("coldStart", isColdStart)
                .put("processingTimeMs", totalMs);

        try {
            return APIGatewayV2HTTPResponse.builder()
                    .withStatusCode(authorized ? 200 : 403)
                    .withHeaders(Map.of("Content-Type", "application/json"))
                    .withBody(MAPPER.writeValueAsString(body))
                    .build();
        } catch (Exception e) {
            return APIGatewayV2HTTPResponse.builder()
                    .withStatusCode(500)
                    .withBody("{\"error\":\"internal\"}")
                    .build();
        }
    }

    private String extractToken(String requestBody) {
        if (requestBody == null || requestBody.isBlank()) {
            return defaultToken();
        }
        try {
            Map<?, ?> parsed = MAPPER.readValue(requestBody, Map.class);
            Object token = parsed.get("token");
            return token != null ? token.toString() : defaultToken();
        } catch (Exception e) {
            return defaultToken();
        }
    }

    // Header: {"alg":"HS256","typ":"JWT"}  Payload: {"sub":"bench-user","iat":1700000000,"exp":9999999999}
    private String defaultToken() {
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
                + ".eyJzdWIiOiJiZW5jaC11c2VyIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjk5OTk5OTk5OTl9"
                + ".mock-signature-not-verified";
    }

    /**
     * Simulates real authz work: decode the JWT payload, run a SHA-256 loop to
     * mimic HMAC verification, and do a simple policy check. The 50-iteration
     * digest loop provides consistent CPU work without depending on system calls.
     */
    private boolean validateToken(String token) {
        if (token == null || token.isEmpty()) return false;
        String[] parts = token.split("\\.", -1);
        if (parts.length != 3) return false;

        try {
            byte[] payloadBytes = Base64.getUrlDecoder().decode(padBase64(parts[1]));
            String payload = new String(payloadBytes, StandardCharsets.UTF_8);
            if (!payload.contains("\"sub\"")) return false;

            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] signingInput = (parts[0] + "." + parts[1]).getBytes(StandardCharsets.UTF_8);
            byte[] secret = "benchmark-secret-key-32-bytes!!".getBytes(StandardCharsets.UTF_8);

            digest.update(secret);
            digest.update(signingInput);
            byte[] hash = digest.digest();

            for (int i = 0; i < 50; i++) {
                digest.reset();
                digest.update(hash);
                hash = digest.digest();
            }

            return hash.length == 32;
        } catch (Exception e) {
            return false;
        }
    }

    private String extractSubject(String token) {
        try {
            String[] parts = token.split("\\.", -1);
            byte[] payloadBytes = Base64.getUrlDecoder().decode(padBase64(parts[1]));
            Map<?, ?> claims = MAPPER.readValue(payloadBytes, Map.class);
            Object sub = claims.get("sub");
            return sub != null ? sub.toString() : "unknown";
        } catch (Exception e) {
            return "unknown";
        }
    }

    private static String padBase64(String s) {
        return switch (s.length() % 4) {
            case 2 -> s + "==";
            case 3 -> s + "=";
            default -> s;
        };
    }
}
