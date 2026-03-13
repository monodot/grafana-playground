import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

public class Server {
    public static void main(String[] args) throws IOException {
        int port = 18081;
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);

        // Called autonomously by node-client on a timer
        server.createContext("/ping", exchange -> {
            log(exchange);
            respond(exchange, "pong");
        });

        // Called by node-client when a user triggers /search on node-client
        server.createContext("/search", exchange -> {
            log(exchange);
            respond(exchange, "search results from Java server");
        });

        server.start();
        System.out.printf("Java HTTP server listening on port %d%n", port);
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