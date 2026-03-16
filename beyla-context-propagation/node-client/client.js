const http = require('http');

const JAVA_SERVER_HOST = process.env.JAVA_SERVER_HOST || 'java-server';
const JAVA_SERVER_PORT = parseInt(process.env.JAVA_SERVER_PORT || '8081');
const JAVA_OTEL_SERVER_HOST = process.env.JAVA_OTEL_SERVER_HOST || 'java-otel-server';
const JAVA_OTEL_SERVER_PORT = parseInt(process.env.JAVA_OTEL_SERVER_PORT || '18082');
const LISTEN_PORT = parseInt(process.env.LISTEN_PORT || '3001');
const INTERVAL_MS = parseInt(process.env.INTERVAL_MS || '5000');

function callUpstream(host, port, path, label, res) {
    const options = { hostname: host, port, path, method: 'GET' };

    const req = http.request(options, (upstreamRes) => {
        let body = '';
        upstreamRes.on('data', chunk => body += chunk);
        upstreamRes.on('end', () => {
            console.log(`[${label}] upstream responded [${upstreamRes.statusCode}]: ${body.trim()}`);
            if (res) {
                res.writeHead(200, { 'Content-Type': 'text/plain' });
                res.end(`${body.trim()}\n`);
            }
        });
    });

    req.on('error', (err) => {
        console.error(`[${label}] Error calling upstream: ${err.message}`);
        if (res) {
            res.writeHead(502, { 'Content-Type': 'text/plain' });
            res.end(`Error: ${err.message}\n`);
        }
    });

    req.end();
}

// Autonomous periodic ping: node-client → java-server /ping
console.log(`Pinging ${JAVA_SERVER_HOST}:${JAVA_SERVER_PORT}/ping every ${INTERVAL_MS}ms`);
setInterval(() => callUpstream(JAVA_SERVER_HOST, JAVA_SERVER_PORT, '/ping', 'auto-ping'), INTERVAL_MS);

// HTTP server: Beyla discovery port + manual triggers
const server = http.createServer((req, res) => {
    if (req.method === 'GET' && req.url === '/search') {
        // node-client → java-server /search (Beyla-only instrumented)
        console.log('[manual] Received /search, calling java-server /search');
        callUpstream(JAVA_SERVER_HOST, JAVA_SERVER_PORT, '/search', 'manual-search', res);
    } else if (req.method === 'GET' && req.url === '/catalog') {
        // node-client → java-otel-server /catalog (OTel SDK instrumented)
        console.log('[manual] Received /catalog, calling java-otel-server /catalog');
        callUpstream(JAVA_OTEL_SERVER_HOST, JAVA_OTEL_SERVER_PORT, '/catalog', 'manual-catalog', res);
    } else {
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('node-client running. Try GET /search or GET /catalog\n');
    }
});

server.listen(LISTEN_PORT, () => {
    console.log(`Listening on port ${LISTEN_PORT}`);
});