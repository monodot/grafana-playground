import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.List;
import java.util.Random;

public class App {

    private static final List<String> TITLES = List.of(
        "intro_montage.mp4",
        "product_demo_2025.mp4",
        "tutorial_part_1.mp4",
        "tutorial_part_2.mp4",
        "marketing_clip.mp4",
        "customer_testimonial.mp4",
        "webinar_recording.mp4",
        "trailer_v3.mp4",
        "annual_review.mp4",
        "behind_the_scenes.mp4"
    );

    private static final List<String> RESOLUTIONS = List.of("480p", "720p", "1080p", "1440p", "4k");
    private static final List<String> CODECS = List.of("h264", "h265", "vp9", "av1");

    public static void main(String[] args) throws Exception {
        String tenantId = envOrDefault("TENANT_ID", "tenant-default");
        long minIdleMs = parseLong("MIN_INTERVAL_MS", 2000);
        long maxIdleMs = parseLong("MAX_INTERVAL_MS", 6000);
        long minProcMs = parseLong("MIN_PROCESSING_MS", 500);
        long maxProcMs = parseLong("MAX_PROCESSING_MS", 8000);
        int failOneIn = (int) parseLong("BASELINE_FAILURE_RATE_DENOM", 20);
        int brokenFailOneIn = (int) parseLong("BROKEN_FAILURE_RATE_DENOM", 2);
        int healthPort = (int) parseLong("HEALTH_PORT", 8080);
        Path breakFlag = Path.of(envOrDefault("BREAK_FLAG_FILE", "/break/" + tenantId));

        HttpServer health = HttpServer.create(new InetSocketAddress(healthPort), 0);
        health.createContext("/health", exchange -> {
            exchange.sendResponseHeaders(200, -1);
            exchange.close();
        });
        health.start();
        log(tenantId, "INFO", "health endpoint listening", "port=" + healthPort);

        log(tenantId, "INFO", "video processor starting", null);

        Random rng = new Random();
        while (true) {
            String videoId = "vid_" + Long.toHexString(rng.nextLong() & 0xffffffffL);
            String title = pick(TITLES, rng);
            String resolution = pick(RESOLUTIONS, rng);
            String codec = pick(CODECS, rng);
            long sizeMb = 50 + rng.nextInt(1950);

            log(tenantId, "INFO", "processing started",
                "video_id=" + videoId + " title=" + title +
                " resolution=" + resolution + " codec=" + codec +
                " size_mb=" + sizeMb);

            long start = System.currentTimeMillis();
            long processingMs = minProcMs + (long) (rng.nextDouble() * (maxProcMs - minProcMs));
            Thread.sleep(processingMs);
            long elapsed = System.currentTimeMillis() - start;

            boolean broken = Files.exists(breakFlag);
            int currentFailOneIn = broken ? brokenFailOneIn : failOneIn;
            if (currentFailOneIn > 0 && rng.nextInt(currentFailOneIn) == 0) {
                log(tenantId, "ERROR", "processing failed",
                    "video_id=" + videoId + " duration_ms=" + elapsed +
                    " reason=transcoder_error");
                if (broken) {
                    logTranscoderException(tenantId, videoId, codec, resolution);
                }
            } else {
                log(tenantId, "INFO", "processing completed",
                    "video_id=" + videoId + " duration_ms=" + elapsed +
                    " resolution=" + resolution + " codec=" + codec +
                    " size_mb=" + sizeMb);
            }

            long idle = minIdleMs + (long) (rng.nextDouble() * (maxIdleMs - minIdleMs));
            Thread.sleep(idle);
        }
    }

    private static <T> T pick(List<T> list, Random rng) {
        return list.get(rng.nextInt(list.size()));
    }

    private static String envOrDefault(String name, String def) {
        String v = System.getenv(name);
        return (v == null || v.isBlank()) ? def : v;
    }

    private static long parseLong(String name, long def) {
        String v = System.getenv(name);
        if (v == null || v.isBlank()) return def;
        try { return Long.parseLong(v); } catch (NumberFormatException e) { return def; }
    }

    private static void log(String tenant, String level, String msg, String extras) {
        StringBuilder sb = new StringBuilder();
        sb.append("ts=").append(Instant.now())
          .append(" level=").append(level)
          .append(" msg=\"").append(msg).append('"');
        if (extras != null) sb.append(' ').append(extras);
        System.out.println(sb);
    }

    private static void logTranscoderException(String tenant, String videoId, String codec, String resolution) {
        NullPointerException e = new NullPointerException(
            "Cannot invoke \"com.videoapp.codec.CodecProfile.getBitrate()\" because the return value of " +
            "\"com.videoapp.codec.CodecRegistry.lookup(String)\" is null"
        );
        e.setStackTrace(new StackTraceElement[] {
            new StackTraceElement("com.videoapp.codec.CodecRegistry", "lookup", "CodecRegistry.java", 82),
            new StackTraceElement("com.videoapp.processor.TranscoderWorker", "selectProfile", "TranscoderWorker.java", 213),
            new StackTraceElement("com.videoapp.processor.TranscoderWorker", "transcode", "TranscoderWorker.java", 147),
            new StackTraceElement("com.videoapp.processor.JobRunner", "execute", "JobRunner.java", 62),
            new StackTraceElement("java.util.concurrent.ThreadPoolExecutor", "runWorker", "ThreadPoolExecutor.java", 1136),
            new StackTraceElement("java.util.concurrent.ThreadPoolExecutor$Worker", "run", "ThreadPoolExecutor.java", 635),
            new StackTraceElement("java.lang.Thread", "run", "Thread.java", 1583),
        });
        log(tenant, "ERROR", "uncaught exception in transcoder worker",
            "video_id=" + videoId + " codec=" + codec + " resolution=" + resolution +
            " exception=java.lang.NullPointerException");
        e.printStackTrace(System.out);
    }
}