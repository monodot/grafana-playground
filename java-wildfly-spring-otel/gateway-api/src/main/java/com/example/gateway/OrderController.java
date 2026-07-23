package com.example.gateway;

import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

@RestController
public class OrderController {

    private final RestClient legacyClient;

    public OrderController(@Value("${legacy.url}") String legacyUrl) {
        this.legacyClient = RestClient.builder().baseUrl(legacyUrl).build();
    }

    @PostMapping("/orders")
    public ResponseEntity<String> createOrder(
            @RequestBody String body,
            @RequestHeader(value = "X-Customer-Id", defaultValue = "CUST-UNKNOWN") String customerId,
            @RequestHeader(value = "X-User-Id", defaultValue = "anonymous") String userId,
            @RequestHeader(value = "Authorization", defaultValue = "") String authorization) {

        // Simulated fraud check that fails for ~10% of customers, so the demo
        // always has some error traces to filter on.
        if (customerId.endsWith("7")) {
            throw new IllegalStateException("Fraud check failed for customer " + customerId);
        }

        String result = legacyClient.post()
                .uri("/orders")
                .header("Content-Type", "application/json")
                .header("X-Customer-Id", customerId)
                .header("X-User-Id", userId)
                .header("Authorization", authorization)
                .body(body)
                .retrieve()
                .body(String.class);

        return ResponseEntity.ok(result);
    }

    @GetMapping("/orders/summary")
    public Map<String, Object> summary() {
        return Map.of("service", "gateway-api", "ordersToday", 42, "status", "ok");
    }
}
