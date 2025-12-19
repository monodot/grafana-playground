package com.example.camel;

import org.apache.camel.builder.RouteBuilder;
import org.springframework.stereotype.Component;

@Component
public class BatchProcessorRoute extends RouteBuilder {

    @Override
    public void configure() throws Exception {

        // Error handling route
        onException(Exception.class)
                .handled(true)
                .log("Error processing batch: ${exception.message}")
                .to("jms:queue:orders.dlq");

        // Batch processing route: Poll database -> Transform -> Send to JMS
        from("sql:SELECT id, order_number, customer_name, amount, status " +
             "FROM orders " +
             "WHERE status = 'PENDING' " +
             "ORDER BY id " +
             "?dataSource=#dataSource" +
             "&onConsume=UPDATE orders SET status = 'PROCESSING' WHERE id = :#id" +
             "&initialDelay=5000" +
             "&delay=10000" +
             "&maxMessagesPerPoll=50")
            .routeId("database-batch-poller")
            .log("Processing batch of ${header.CamelBatchSize} orders, index: ${header.CamelBatchIndex}")

            // Add trace context to message
            .setHeader("orderNumber", simple("${body[order_number]}"))
            .setHeader("customerId", simple("${body[customer_name]}"))

            // Transform to JSON message
            .marshal().json()
            .convertBodyTo(String.class)

            // Log the message
            .log("Sending order ${header.orderNumber} to JMS: ${body}")

            // Send to ActiveMQ
            .to("jms:queue:orders.processing")

            // Update status in database
            .setBody(simple("${header.CamelBatchIndex}"))
            .to("sql:UPDATE orders SET status = 'SENT', processed_at = CURRENT_TIMESTAMP WHERE id = :#${body}?dataSource=#dataSource")

            .log("Successfully processed order ${header.orderNumber}");

    }
}
