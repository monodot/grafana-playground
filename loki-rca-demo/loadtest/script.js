import http from 'k6/http';
import { sleep, check } from 'k6';
import { randomItem } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export const options = {
  vus: 1,
  duration: '30s',
};

const tenants = ['acmeco', 'excelsior', 'wavetron'];

export default function() {
  const tenant = randomItem(tenants);
  let data = { tenant };

  let res = http.post('http://ingest-service:8080/ingest', data); // x-form-urlencoded
  check(res, { "status is 200": (res) => res.status === 200 });
  sleep(1);
}
