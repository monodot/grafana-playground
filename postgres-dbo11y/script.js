import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  vus: 1,
  duration: '30m',
};

const BASE_URL = 'http://snacks-api:3000';

const snackNames = ['Chips', 'Cookies', 'Candy', 'Pretzels', 'Popcorn', 'Nuts', 'Crackers', 'Chocolate'];
const snackDescriptions = [
  'Crispy and delicious',
  'Sweet and crunchy',
  'A tasty treat',
  'Perfect for snacking',
  'Light and fluffy',
  'Salty goodness',
];

function randomSnack() {
  return {
    name: snackNames[Math.floor(Math.random() * snackNames.length)],
    description: snackDescriptions[Math.floor(Math.random() * snackDescriptions.length)],
    price: (Math.random() * 10 + 0.99).toFixed(2),
  };
}

export default function() {
  // Health check
  let healthRes = http.get(`${BASE_URL}/health`);
  check(healthRes, { 'health check is 200': (r) => r.status === 200 });

  // Create a snack
  let snack = randomSnack();
  let createRes = http.post(
    `${BASE_URL}/snacks`,
    JSON.stringify(snack),
    { headers: { 'Content-Type': 'application/json' } }
  );
  check(createRes, {
    'create snack is 201': (r) => r.status === 201,
    'create snack returns id': (r) => JSON.parse(r.body).id !== undefined,
  });

  let createdSnack = JSON.parse(createRes.body);
  sleep(0.5);

  // Get all snacks
  let listRes = http.get(`${BASE_URL}/snacks`);
  check(listRes, {
    'list snacks is 200': (r) => r.status === 200,
    'list snacks returns array': (r) => Array.isArray(JSON.parse(r.body)),
  });
  sleep(0.5);

  // Get the created snack by ID
  if (createdSnack.id) {
    let getRes = http.get(`${BASE_URL}/snacks/${createdSnack.id}`);
    check(getRes, {
      'get snack is 200': (r) => r.status === 200,
      'get snack returns correct id': (r) => JSON.parse(r.body).id === createdSnack.id,
    });
    sleep(0.5);

    // Update the snack
    let updateRes = http.put(
      `${BASE_URL}/snacks/${createdSnack.id}`,
      JSON.stringify({ price: (parseFloat(createdSnack.price) + 0.50).toFixed(2) }),
      { headers: { 'Content-Type': 'application/json' } }
    );
    check(updateRes, { 'update snack is 200': (r) => r.status === 200 });
    sleep(0.5);

    // Delete the snack
    let deleteRes = http.del(`${BASE_URL}/snacks/${createdSnack.id}`);
    check(deleteRes, { 'delete snack is 200': (r) => r.status === 200 });
    sleep(0.5);

    // Verify deletion
    let verifyRes = http.get(`${BASE_URL}/snacks/${createdSnack.id}`);
    check(verifyRes, { 'deleted snack returns 404': (r) => r.status === 404 });
  }

  sleep(1);
}
