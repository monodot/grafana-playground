package com.example.batch;

import java.util.List;
import java.util.Map;

import io.opentelemetry.instrumentation.annotations.WithSpan;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * A "normal batch job": reads pending rows from Oracle, submits each one to the
 * gateway API, and marks it as exported.
 *
 * The trace root for each run is created by the OTel Java agent via
 * OTEL_INSTRUMENTATION_METHODS_INCLUDE=com.example.batch.NightlyExportJob[runExport]
 * (see compose.yaml) - the batch job has no incoming request, so without this the
 * agent would not start a trace.
 */
@Component
public class NightlyExportJob {

    private static final Logger log = LoggerFactory.getLogger(NightlyExportJob.class);

    private final JdbcTemplate jdbc;
    private final RestClient gatewayClient;

    public NightlyExportJob(JdbcTemplate jdbc, @Value("${gateway.url}") String gatewayUrl) {
        this.jdbc = jdbc;
        this.gatewayClient = RestClient.builder().baseUrl(gatewayUrl).build();
    }

    @Scheduled(initialDelay = 15_000, fixedDelay = 60_000)
    public void runExport() {
        List<Map<String, Object>> pending = jdbc.queryForList(
                "SELECT id, customer_id, item, quantity FROM pending_exports "
                + "WHERE status = 'PENDING' ORDER BY id FETCH FIRST 5 ROWS ONLY");

        if (pending.isEmpty()) {
            log.info("No pending exports; resetting all rows to PENDING for the next run");
            jdbc.update("UPDATE pending_exports SET status = 'PENDING'");
            return;
        }

        log.info("Exporting {} pending orders", pending.size());
        for (Map<String, Object> row : pending) {
            process(row);
        }
    }

    // @WithSpan is the code-based way to add a span; the runExport root span above
    // is the config-based way. The demo shows both side by side.
    @WithSpan
    void process(Map<String, Object> row) {
        long id = ((Number) row.get("id")).longValue();
        String customerId = (String) row.get("customer_id");
        String body = String.format("{\"customerId\":\"%s\",\"item\":\"%s\",\"quantity\":%d}",
                customerId, row.get("item"), ((Number) row.get("quantity")).longValue());

        try {
            gatewayClient.post()
                    .uri("/orders")
                    .header("Content-Type", "application/json")
                    .header("X-Customer-Id", customerId)
                    .header("X-User-Id", "batch-job")
                    .header("Authorization", "Bearer demo-token-not-a-real-secret")
                    .body(body)
                    .retrieve()
                    .body(String.class);
            jdbc.update("UPDATE pending_exports SET status = 'EXPORTED' WHERE id = ?", id);
        } catch (Exception e) {
            log.warn("Export of row {} failed: {}", id, e.getMessage());
            jdbc.update("UPDATE pending_exports SET status = 'FAILED' WHERE id = ?", id);
        }
    }
}
