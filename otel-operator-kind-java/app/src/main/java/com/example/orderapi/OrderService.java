package com.example.orderapi;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import org.springframework.stereotype.Service;

@Service
public class OrderService {

  private static final List<String> ITEMS = List.of("widget", "sprocket", "flange", "grommet");

  public Map<String, Object> findOrder(String id) {
    simulateWork(20, 80);
    return Map.of(
        "orderId", id,
        "item", ITEMS.get(ThreadLocalRandom.current().nextInt(ITEMS.size())),
        "quantity", ThreadLocalRandom.current().nextInt(1, 10),
        "status", "confirmed");
  }

  public Map<String, Object> buildInvoice(String id) {
    Map<String, Object> order = findOrder(id);
    simulateWork(40, 150);
    int quantity = (int) order.get("quantity");
    return Map.of(
        "invoiceId", "INV-" + id,
        "orderId", id,
        "lines", quantity,
        "total", quantity * 12.50);
  }

  private void simulateWork(int minMillis, int maxMillis) {
    try {
      Thread.sleep(ThreadLocalRandom.current().nextInt(minMillis, maxMillis));
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
    }
  }
}
