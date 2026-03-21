/**
 * k6 benchmark script for the AWS Lambda OTel overhead matrix.
 *
 * Usage:
 *   FUNCTION_URL=https://xxx.lambda-url.us-east-1.on.aws/ \
 *   CONFIG_NAME=c4-col-layer \
 *   k6 run k6/benchmark.js
 *
 * Each run executes two scenarios:
 *   burst       - High-concurrency burst to force cold starts, then cool-down
 *   warm        - Sustained constant rate for warm-invocation p50/p99 (≥1000 reqs)
 *
 * Cold starts are detected from the "coldStart": true field in the response body.
 * Metrics are written to k6/results/<CONFIG_NAME>-<timestamp>.csv.
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';

// ── Custom metrics ────────────────────────────────────────────────────────────

const coldStartDuration = new Trend('cold_start_duration_ms', true);
const warmDuration      = new Trend('warm_duration_ms', true);
const coldStartCount    = new Counter('cold_start_count');

// ── Config ────────────────────────────────────────────────────────────────────

const FUNCTION_URL = __ENV.FUNCTION_URL;
const CONFIG_NAME  = __ENV.CONFIG_NAME || 'unknown';

if (!FUNCTION_URL) {
  throw new Error('FUNCTION_URL environment variable is required');
}

const PAYLOAD = JSON.stringify({
  token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
       + '.eyJzdWIiOiJiZW5jaC11c2VyIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjk5OTk5OTk5OTl9'
       + '.mock-signature-not-verified',
});

const HEADERS = { 'Content-Type': 'application/json' };

// ── Scenarios ─────────────────────────────────────────────────────────────────

export const options = {
  scenarios: {
    // Burst to concurrent invocations to force multiple cold starts, then back off.
    burst: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '10s', target: 50 },  // ramp up sharply
        { duration: '20s', target: 50 },  // hold — cold starts happen here
        { duration: '10s', target: 0  },  // cool down
      ],
      gracefulRampDown: '5s',
    },
    // Steady low-concurrency load for warm-path measurements (≥1000 invocations).
    warm: {
      executor: 'constant-arrival-rate',
      rate: 10,
      timeUnit: '1s',
      duration: '120s',       // 10 RPS × 120 s = 1200 invocations
      preAllocatedVUs: 15,
      maxVUs: 30,
      startTime: '50s',       // starts after the burst scenario ends
    },
  },

  thresholds: {
    // Loose upper bounds — these are observation thresholds, not SLOs.
    warm_duration_ms: ['p(99)<5000'],
    http_req_failed:  ['rate<0.01'],
  },

  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)', 'count'],

  cloud: {
    name: `Lambda OTel Benchmark — ${CONFIG_NAME}`,
    tags: { config: CONFIG_NAME },
  },
};

// ── Default function ──────────────────────────────────────────────────────────

export default function () {
  const res = http.post(FUNCTION_URL, PAYLOAD, {
    headers: HEADERS,
    timeout: '30s',
  });

  const ok = check(res, {
    'status 200 or 403': (r) => r.status === 200 || r.status === 403,
  });

  if (!ok) return;

  let body;
  try {
    body = JSON.parse(res.body);
  } catch (_) {
    return;
  }

  const duration = res.timings.duration;

  const tags = { config: CONFIG_NAME };
  if (body.coldStart === true) {
    coldStartDuration.add(duration, tags);
    coldStartCount.add(1, tags);
  } else {
    warmDuration.add(duration, tags);
  }
}

// ── Summary ───────────────────────────────────────────────────────────────────

export function handleSummary(data) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const csvPath   = `k6/results/${CONFIG_NAME}-${timestamp}.csv`;

  // Print a readable summary to stdout and write CSV for later analysis.
  return {
    stdout: buildTextSummary(data),
    [csvPath]: toCsv(data),
  };
}

function buildTextSummary(data) {
  const lines = [
    `\n=== ${CONFIG_NAME} ===`,
    `Cold starts detected : ${metricValue(data, 'cold_start_count', 'count') || 0}`,
    `Cold start p50       : ${metricValue(data, 'cold_start_duration_ms', 'med')} ms`,
    `Cold start p99       : ${metricValue(data, 'cold_start_duration_ms', 'p(99)')} ms`,
    `Warm p50             : ${metricValue(data, 'warm_duration_ms', 'med')} ms`,
    `Warm p99             : ${metricValue(data, 'warm_duration_ms', 'p(99)')} ms`,
    `Warm requests        : ${metricValue(data, 'warm_duration_ms', 'count')}`,
    '',
  ];
  return lines.join('\n');
}

function metricValue(data, name, stat) {
  const m = data.metrics[name];
  if (!m) return 'n/a';
  const v = m.values[stat];
  return v !== undefined ? Math.round(v) : 'n/a';
}

function toCsv(data) {
  const rows = ['config,metric,stat,value'];
  for (const [name, metric] of Object.entries(data.metrics)) {
    for (const [stat, value] of Object.entries(metric.values)) {
      rows.push(`${CONFIG_NAME},${name},${stat},${value}`);
    }
  }
  return rows.join('\n') + '\n';
}
