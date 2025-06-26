const { v4: uuidv4 } = require("uuid");

const logMessages = [
  "Processing user request",
  "Fetching data from database",
  "Updating user profile",
  "Sending notification to user",
  "Validating input parameters",
  "Caching query results",
  "Initiating background job",
  "Performing data cleanup",
  "Checking user permissions",
  "Optimizing database query",
];

function getRandomMessage() {
  return logMessages[Math.floor(Math.random() * logMessages.length)];
}

function getRandomLevel() {
  return Math.random() < 0.9 ? "info" : "warn";
}

function getRandomCustomerId() {
  return Math.floor(Math.random() * 10000) + 1;
}

exports.handler = async (event) => {
  const logEntry = {
    invocation: uuidv4(),
    customerId: getRandomCustomerId(),
    level: getRandomLevel(),
    message: getRandomMessage(),
  };

  console.log(JSON.stringify(logEntry));

  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({message: "Function executed successfully"}),
  };
};
