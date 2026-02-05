import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  vus: 5,
  duration: '15m',
};

const BASE_URL = __ENV.HOST || 'http://localhost';

export default function() {
  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  // Check Redis status
  let res = http.get(`${BASE_URL}/api/redis/status`);
  check(res, { 'Redis status check successful': (r) => r.status === 200 });
  sleep(1);

  // GET all values
  res = http.get(`${BASE_URL}/api/values`);
  check(res, { 'GET values successful': (r) => r.status === 200 });
  sleep(1);

  // POST create a new value
  const valueId = Math.floor(Math.random() * 10000);
  res = http.post(
    `${BASE_URL}/api/values`,
    '"test-value-' + valueId + '"',
    { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
  );
  check(res, { 'POST value successful': (r) => r.status === 200 || r.status === 201 });
  sleep(1);

  // GET specific value
  res = http.get(`${BASE_URL}/api/values/${valueId}`);
  check(res, { 'GET specific value successful': (r) => r.status === 200 });
  sleep(1);

  // PUT update a value
  res = http.put(
    `${BASE_URL}/api/values/${valueId}`,
    '"updated-value"',
    { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
  );
  check(res, { 'PUT value successful': (r) => r.status === 200 || r.status === 204 });
  sleep(1);

  // POST create a Redis key
  const redisKey = `testkey-${__VU}-${Date.now()}`;
  res = http.post(
    `${BASE_URL}/api/redis`,
    JSON.stringify({
      key: redisKey,
      value: 'test-data-' + Math.random()
    }),
    params
  );
  check(res, { 'POST Redis key successful': (r) => r.status === 200 || r.status === 201 });
  sleep(1);

  // GET Redis key
  res = http.get(`${BASE_URL}/api/redis/${redisKey}`);
  check(res, { 'GET Redis key successful': (r) => r.status === 200 });
  sleep(1);

  // DELETE Redis key
  res = http.del(`${BASE_URL}/api/redis/${redisKey}`);
  check(res, { 'DELETE Redis key successful': (r) => r.status === 200 || r.status === 204 });
  sleep(1);

  // DELETE value
  res = http.del(`${BASE_URL}/api/values/${valueId}`);
  check(res, { 'DELETE value successful': (r) => r.status === 200 || r.status === 204 });
  sleep(1);
}
