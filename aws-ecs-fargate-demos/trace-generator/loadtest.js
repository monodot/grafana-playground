import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  vus: 2,
  duration: '1h',
};

const API_URL = __ENV.API_URL || 'http://localhost:3000';

export default function() {
  let res = http.get(`${API_URL}/packages`);
  check(res, { "status is 200": (res) => res.status === 200 });
  sleep(1);
}
