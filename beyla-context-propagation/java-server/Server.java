import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.sql.*;

public class Server {
    private static Connection dbConnection;

    public static void main(String[] args) throws IOException {
        String dbUrl = System.getenv().getOrDefault("DB_URL", "jdbc:postgresql://localhost:5432/demo");
        String dbUser = System.getenv().getOrDefault("DB_USER", "demo");
        String dbPassword = System.getenv().getOrDefault("DB_PASSWORD", "demo");

        try {
            dbConnection = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
            System.out.println("Connected to PostgreSQL");
        } catch (SQLException e) {
            System.err.println("Failed to connect to database: " + e.getMessage());
            System.exit(1);
        }

        int port = 18081;
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);

        // Called autonomously by node-client on a timer
        server.createContext("/ping", exchange -> {
            log(exchange);
            respond(exchange, "pong");
        });

        // Called by node-client when a user triggers /search on node-client
        // Queries the products table in PostgreSQL
        server.createContext("/search", exchange -> {
            log(exchange);
            respond(exchange, queryProducts());
        });

        server.start();
        System.out.printf("Java HTTP server listening on port %d%n", port);
    }

    private static String queryProducts() {
        try (Statement stmt = dbConnection.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT name, description FROM products ORDER BY id")) {
            StringBuilder sb = new StringBuilder();
            while (rs.next()) {
                sb.append(rs.getString("name"))
                  .append(": ")
                  .append(rs.getString("description"))
                  .append("\n");
            }
            return sb.isEmpty() ? "no products found" : sb.toString().trim();
        } catch (SQLException e) {
            return "DB error: " + e.getMessage();
        }
    }

    private static void log(HttpExchange exchange) {
        System.out.printf("Received %s %s%n",
            exchange.getRequestMethod(), exchange.getRequestURI().getPath());
    }

    private static void respond(HttpExchange exchange, String body) throws IOException {
        byte[] bytes = body.getBytes();
        exchange.sendResponseHeaders(200, bytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(bytes);
        }
    }
}