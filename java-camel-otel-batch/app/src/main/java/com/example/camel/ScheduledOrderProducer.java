package com.example.camel;

import org.apache.camel.ProducerTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

@Component
public class ScheduledOrderProducer {

    private static final Logger logger = LoggerFactory.getLogger(ScheduledOrderProducer.class);
    private final Random random = new Random();

    @Autowired
    private ProducerTemplate producerTemplate;

    @Scheduled(fixedRate = 10000) // Every 10 seconds
    public void sendOrders() {
        logger.info("Starting scheduled order production - sending 5 orders");

        for (int i = 1; i <= 5; i++) {
            Map<String, Object> order = new HashMap<>();
            order.put("order_number", "SCHED-" + System.currentTimeMillis() + "-" + i);
            order.put("customer_name", "Customer-" + random.nextInt(1000));
            order.put("amount", 100.0 + random.nextDouble() * 400.0);
            order.put("status", "SCHEDULED");

            try {
                producerTemplate.sendBody("direct:sendOrder", order);
                logger.info("Sent order {} of 5: {}", i, order.get("order_number"));
            } catch (Exception e) {
                logger.error("Failed to send order {}: {}", i, e.getMessage());
            }
        }

        logger.info("Completed scheduled order production");
    }
}
