package com.example.legacy;

import java.io.BufferedReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.json.JSONObject;

@WebServlet("/orders")
public class OrderServlet extends HttpServlet {

    private String dbUrl;
    private String dbUser;
    private String dbPassword;

    @Override
    public void init() throws ServletException {
        dbUrl = getenv("DB_URL", "jdbc:oracle:thin:@//localhost:1521/FREEPDB1");
        dbUser = getenv("DB_USER", "orders");
        dbPassword = getenv("DB_PASSWORD", "ordersdemo1");
        try {
            Class.forName("oracle.jdbc.OracleDriver");
        } catch (ClassNotFoundException e) {
            throw new ServletException("Oracle JDBC driver not found", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        JSONObject order = new JSONObject(readBody(req));
        String customerId = order.optString("customerId", "CUST-UNKNOWN");
        String item = order.optString("item", "unknown-item");
        int quantity = order.optInt("quantity", 1);

        try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
             PreparedStatement stmt = conn.prepareStatement(
                     "INSERT INTO orders (customer_id, item, quantity, source) VALUES (?, ?, ?, ?)")) {
            stmt.setString(1, customerId);
            stmt.setString(2, item);
            stmt.setInt(3, quantity);
            stmt.setString(4, headerOrDefault(req, "X-User-Id", "unknown"));
            stmt.executeUpdate();
        } catch (SQLException e) {
            throw new ServletException("Failed to insert order", e);
        }

        resp.setStatus(HttpServletResponse.SC_CREATED);
        resp.setContentType("application/json");
        resp.getWriter().write("{\"status\":\"created\",\"customerId\":\"" + customerId + "\"}");
    }

    private static String readBody(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
        }
        return sb.toString();
    }

    private static String headerOrDefault(HttpServletRequest req, String name, String def) {
        String value = req.getHeader(name);
        return value != null ? value : def;
    }

    private static String getenv(String name, String def) {
        String value = System.getenv(name);
        return value != null ? value : def;
    }
}
