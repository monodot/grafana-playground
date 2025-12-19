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

        // Direct route: Send message to orders queue
        from("direct:sendOrder")
            .routeId("direct-order-sender")
            .log("Sending message to orders queue: ${body}")
            .marshal().json()
            .to("jms:queue:orders.processing");

        // Consumer route: Process orders from queue and save to database
        from("jms:queue:orders.processing")
            .routeId("order-queue-consumer")
            .log("Received order from queue: ${body}")
            .unmarshal().json()
            .log("Processing order: ${body[order_number]}")
            .setHeader("orderNumber", simple("${body[order_number]}"))
            .setHeader("customerName", simple("${body[customer_name]}"))
            .setHeader("amount", simple("${body[amount]}"))
            .setHeader("status", simple("${body[status]}"))
            .to("sql:INSERT INTO orders (order_number, customer_name, amount, status, created_at) " +
                "VALUES (:#${header.orderNumber}, :#${header.customerName}, :#${header.amount}, :#${header.status}, CURRENT_TIMESTAMP) " +
                "ON CONFLICT (order_number) DO UPDATE SET " +
                "customer_name = EXCLUDED.customer_name, " +
                "amount = EXCLUDED.amount, " +
                "status = EXCLUDED.status, " +
                "processed_at = CURRENT_TIMESTAMP" +
                "?dataSource=#dataSource")
            .log("Successfully saved order ${header.orderNumber} to database");

    }
}
