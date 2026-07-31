package com.example.orderapi;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class OrderController {

  private final OrderService orderService;

  public OrderController(OrderService orderService) {
    this.orderService = orderService;
  }

  @GetMapping("/")
  public Map<String, String> index() {
    return Map.of("service", "order-api", "status", "ok");
  }

  @GetMapping("/orders/{id}")
  public Map<String, Object> getOrder(@PathVariable String id) {
    return orderService.findOrder(id);
  }

  @GetMapping("/orders/{id}/invoice")
  public Map<String, Object> getInvoice(@PathVariable String id) {
    return orderService.buildInvoice(id);
  }
}
