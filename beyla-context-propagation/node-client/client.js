const http = require('http');

const JAVA_SERVER_HOST = process.env.JAVA_SERVER_HOST || 'java-server';
const JAVA_SERVER_PORT = parseInt(process.env.JAVA_SERVER_PORT || '8081');
const LISTEN_PORT = parseInt(process.env.LISTEN_PORT || '3001');
const INTERVAL_MS = parseInt(process.env.INTERVAL_MS || '5000');

function callJava(path, label, res) {
    const options = {
        hostname: JAVA_SERVER_HOST,
        port: JAVA_SERVER_PORT,
        path,
        method: 'GET',
    };

    const req = http.request(options, (javaRes) => {
        let body = '';
        javaRes.on('data', chunk => body += chunk);
        javaRes.on('end', () => {
            console.log(`[${label}] Java server responded [${javaRes.statusCode}]: ${body.trim()}`);
            if (res) {
                res.writeHead(200, { 'Content-Type': 'text/plain' });
                res.end(`Java said: ${body.trim()}\n`);
            }
        });
    });

    req.on('error', (err) => {
        console.error(`[${label}] Error calling Java server: ${err.message}`);
        if (res) {
            res.writeHead(502, { 'Content-Type': 'text/plain' });
            res.end(`Error: ${err.message}\n`);
        }
    });

    req.end();
}

// Autonomous periodic ping: node-client → java-server /ping
console.log(`Pinging ${JAVA_SERVER_HOST}:${JAVA_SERVER_PORT}/ping every ${INTERVAL_MS}ms`);
setInterval(() => callJava('/ping', 'auto-ping'), INTERVAL_MS);

// HTTP server: Beyla discovery port + manual /search trigger
const server = http.createServer((req, res) => {
    if (req.method === 'GET' && req.url === '/search') {
        // Manual trigger: node-client → java-server /search
        console.log('[manual] Received /search request, calling Java /search');
        callJava('/search', 'manual-search', res);
    } else {
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('node-client running. Try GET /search\n');
    }
});

server.listen(LISTEN_PORT, () => {
    console.log(`Listening on port ${LISTEN_PORT} — GET /search to manually trigger a Java call`);
});