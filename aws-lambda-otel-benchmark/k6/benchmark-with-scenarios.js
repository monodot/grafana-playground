/**
 * k6 multi-config benchmark for the AWS Lambda OTel overhead matrix.
 *
 * Runs burst + warm scenarios for all five configs in a single k6 run,
 * sequentially so each config gets its own isolated cold-start window.
 * Results are tagged by config name so they can be compared in k6 Cloud.
 *
 * Usage:
 *   C1_BASELINE_URL=https://... \
 *   C2_SDK_URL=https://... \
 *   C3_DIRECT_URL=https://... \
 *   C4_COL_LAYER_URL=https://... \
 *   C5_EXT_COL_URL=https://... \
 *   k6 run k6/benchmark-with-scenarios.js
 *
 * If a URL is not provided, that config's scenarios are skipped.
 *
 * Each config slot is 180 s:
 *   0 s   — burst ramp-up begins (forces cold starts)
 *   50 s  — warm constant-rate begins (1200 warm invocations)
 *   170 s — warm phase ends; 10 s cooldown before next config
 */

import http from 'k6/http';
import { check } from 'k6';
import { Counter, Trend } from 'k6/metrics';

// ── Metrics ────────────────────────────────────────────────────────────────────

const coldStartDuration = new Trend('cold_start_duration_ms', true);
const warmDuration      = new Trend('warm_duration_ms', true);
const coldStartCount    = new Counter('cold_start_count');

// ── Options ────────────────────────────────────────────────────────────────────

export const options = {
  scenarios: {
    // ── Config 1: True baseline ───────────────────────────────────────────────
    c1_baseline_burst: {
      executor: 'ramping-vus',
      startTime: '0s',
      startVUs: 1,
      stages: [
        { duration: '10s', target: 50 },
        { duration: '20s', target: 50 },
        { duration: '10s', target: 0  },
      ],
      gracefulRampDown: '5s',
      env: { FUNCTION_URL: __ENV.C1_BASELINE_URL || '', CONFIG_NAME: 'c1-baseline' },
    },
    c1_baseline_warm: {
      executor: 'constant-arrival-rate',
      startTime: '50s',
      rate: 10,
      timeUnit: '1s',
      duration: '120s',
      preAllocatedVUs: 15,
      maxVUs: 30,
      env: { FUNCTION_URL: __ENV.C1_BASELINE_URL || '', CONFIG_NAME: 'c1-baseline' },
    },

    // ── Config 2: OTel SDK loaded, all exporters disabled ─────────────────────
    c2_sdk_burst: {
      executor: 'ramping-vus',
      startTime: '180s',
      startVUs: 1,
      stages: [
        { duration: '10s', target: 50 },
        { duration: '20s', target: 50 },
        { duration: '10s', target: 0  },
      ],
      gracefulRampDown: '5s',
      env: { FUNCTION_URL: __ENV.C2_SDK_URL || '', CONFIG_NAME: 'c2-sdk' },
    },
    c2_sdk_warm: {
      executor: 'constant-arrival-rate',
      startTime: '230s',
      rate: 10,
      timeUnit: '1s',
      duration: '120s',
      preAllocatedVUs: 15,
      maxVUs: 30,
      env: { FUNCTION_URL: __ENV.C2_SDK_URL || '', CONFIG_NAME: 'c2-sdk' },
    },

    // ── Config 3: Direct export to Grafana Cloud ──────────────────────────────
    c3_direct_burst: {
      executor: 'ramping-vus',
      startTime: '360s',
      startVUs: 1,
      stages: [
        { duration: '10s', target: 50 },
        { duration: '20s', target: 50 },
        { duration: '10s', target: 0  },
      ],
      gracefulRampDown: '5s',
      env: { FUNCTION_URL: __ENV.C3_DIRECT_URL || '', CONFIG_NAME: 'c3-direct' },
    },
    c3_direct_warm: {
      executor: 'constant-arrival-rate',
      startTime: '410s',
      rate: 10,
      timeUnit: '1s',
      duration: '120s',
      preAllocatedVUs: 15,
      maxVUs: 30,
      env: { FUNCTION_URL: __ENV.C3_DIRECT_URL || '', CONFIG_NAME: 'c3-direct' },
    },

    // ── Config 4: Collector Lambda Layer ──────────────────────────────────────
    c4_col_layer_burst: {
      executor: 'ramping-vus',
      startTime: '540s',
      startVUs: 1,
      stages: [
        { duration: '10s', target: 50 },
        { duration: '20s', target: 50 },
        { duration: '10s', target: 0  },
      ],
      gracefulRampDown: '5s',
      env: { FUNCTION_URL: __ENV.C4_COL_LAYER_URL || '', CONFIG_NAME: 'c4-col-layer' },
    },
    c4_col_layer_warm: {
      executor: 'constant-arrival-rate',
      startTime: '590s',
      rate: 10,
      timeUnit: '1s',
      duration: '120s',
      preAllocatedVUs: 15,
      maxVUs: 30,
      env: { FUNCTION_URL: __ENV.C4_COL_LAYER_URL || '', CONFIG_NAME: 'c4-col-layer' },
    },

    // ── Config 5: External ECS Fargate collector ───────────────────────────────
    c5_ext_col_burst: {
      executor: 'ramping-vus',
      startTime: '720s',
      startVUs: 1,
      stages: [
        { duration: '10s', target: 50 },
        { duration: '20s', target: 50 },
        { duration: '10s', target: 0  },
      ],
      gracefulRampDown: '5s',
      env: { FUNCTION_URL: __ENV.C5_EXT_COL_URL || '', CONFIG_NAME: 'c5-ext-col' },
    },
    c5_ext_col_warm: {
      executor: 'constant-arrival-rate',
      startTime: '770s',
      rate: 10,
      timeUnit: '1s',
      duration: '120s',
      preAllocatedVUs: 15,
      maxVUs: 30,
      env: { FUNCTION_URL: __ENV.C5_EXT_COL_URL || '', CONFIG_NAME: 'c5-ext-col' },
    },
  },

  thresholds: {
    http_req_failed: ['rate<0.01'],
    // Sub-metric thresholds — these also make per-config rows appear in handleSummary.
    'cold_start_duration_ms{config:c1-baseline}':  [],
    'cold_start_duration_ms{config:c2-sdk}':       [],
    'cold_start_duration_ms{config:c3-direct}':    [],
    'cold_start_duration_ms{config:c4-col-layer}': [],
    'cold_start_duration_ms{config:c5-ext-col}':   [],
    'warm_duration_ms{config:c1-baseline}':         ['p(99)<5000'],
    'warm_duration_ms{config:c2-sdk}':              ['p(99)<5000'],
    'warm_duration_ms{config:c3-direct}':           ['p(99)<5000'],
    'warm_duration_ms{config:c4-col-layer}':        ['p(99)<5000'],
    'warm_duration_ms{config:c5-ext-col}':          ['p(99)<5000'],
    'cold_start_count{config:c1-baseline}':         [],
    'cold_start_count{config:c2-sdk}':              [],
    'cold_start_count{config:c3-direct}':           [],
    'cold_start_count{config:c4-col-layer}':        [],
    'cold_start_count{config:c5-ext-col}':          [],
  },

  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)', 'count'],

  cloud: {
    name: 'Lambda OTel Benchmark — all configs',
  },
};

// ── Shared request payload ─────────────────────────────────────────────────────

const PAYLOAD = JSON.stringify({
  token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
       + '.eyJzdWIiOiJiZW5jaC11c2VyIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjk5OTk5OTk5OTl9'
       + '.mock-signature-not-verified',
});

const HEADERS = { 'Content-Type': 'application/json' };

// ── Default function ───────────────────────────────────────────────────────────

export default function () {
  if (!__ENV.FUNCTION_URL) return;

  const configName = __ENV.CONFIG_NAME;

  const res = http.post(__ENV.FUNCTION_URL, PAYLOAD, {
    headers: HEADERS,
    timeout: '30s',
    tags: { config: configName },
  });

  const ok = check(res, {
    'status 200 or 403': (r) => r.status === 200 || r.status === 403,
  }, { config: configName });

  if (!ok) return;

  let body;
  try {
    body = JSON.parse(res.body);
  } catch (_) {
    return;
  }

  const tags = { config: configName };
  if (body.coldStart === true) {
    coldStartDuration.add(res.timings.duration, tags);
    coldStartCount.add(1, tags);
  } else {
    warmDuration.add(res.timings.duration, tags);
  }
}

// ── Summary ────────────────────────────────────────────────────────────────────

export function handleSummary(data) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const csvPath   = `k6/results/all-configs-${timestamp}.csv`;

  return {
    stdout:    buildTextSummary(data),
    [csvPath]: toCsv(data),
  };
}

const CONFIGS = ['c1-baseline', 'c2-sdk', 'c3-direct', 'c4-col-layer', 'c5-ext-col'];

function buildTextSummary(data) {
  const pad = (s, w) => String(s ?? 'n/a').padStart(w);
  const header = `${'Config'.padEnd(14)}  ${pad('Cold #', 8)}  ${pad('C p50', 8)}  ${pad('C p99', 8)}  ${pad('W p50', 8)}  ${pad('W p99', 8)}  ${pad('W reqs', 8)}`;
  const divider = '-'.repeat(header.length);

  const lines = ['', '=== Lambda OTel Benchmark — Results ===', '', header, divider];

  for (const name of CONFIGS) {
    lines.push(
      `${name.padEnd(14)}  ` +
      `${pad(mv(data, `cold_start_count{config:${name}}`,       'count'), 8)}  ` +
      `${pad(mv(data, `cold_start_duration_ms{config:${name}}`, 'med'),   8)}  ` +
      `${pad(mv(data, `cold_start_duration_ms{config:${name}}`, 'p(99)'), 8)}  ` +
      `${pad(mv(data, `warm_duration_ms{config:${name}}`,       'med'),   8)}  ` +
      `${pad(mv(data, `warm_duration_ms{config:${name}}`,       'p(99)'), 8)}  ` +
      `${pad(mv(data, `warm_duration_ms{config:${name}}`,       'count'), 8)}`
    );
  }

  lines.push(divider, '(all durations in ms)', '');
  return lines.join('\n');
}

function mv(data, metricName, stat) {
  const m = data.metrics[metricName];
  if (!m) return 'n/a';
  const v = m.values[stat];
  return v !== undefined ? Math.round(v) : 'n/a';
}

function toCsv(data) {
  const rows = ['config,metric,stat,value'];
  for (const [name, metric] of Object.entries(data.metrics)) {
    for (const [stat, value] of Object.entries(metric.values)) {
      rows.push(`,${name},${stat},${value}`);
    }
  }
  return rows.join('\n') + '\n';
}
