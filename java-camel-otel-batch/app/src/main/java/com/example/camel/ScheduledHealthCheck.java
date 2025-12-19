package com.example.camel;

import org.apache.hc.client5.http.classic.methods.HttpGet;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.CloseableHttpResponse;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.core5.http.io.entity.EntityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class ScheduledHealthCheck {

    private static final Logger logger = LoggerFactory.getLogger(ScheduledHealthCheck.class);
    private final CloseableHttpClient httpClient = HttpClients.createDefault();

    @Scheduled(fixedRate = 60000) // Every 1 minute
    public void checkGrafanaWebsite() {
        HttpGet request = new HttpGet("https://grafana.com");

        try (CloseableHttpResponse response = httpClient.execute(request)) {
            logger.info("Performing scheduled health check to grafana.com");
            int statusCode = response.getCode();
            String body = EntityUtils.toString(response.getEntity());
            logger.info("Health check successful, status: {}, received {} bytes", statusCode, body.length());
        } catch (Exception e) {
            logger.error("Health check failed: {}", e.getMessage());
        }
    }
}
