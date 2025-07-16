<?php

use App\Database;
use Monolog\Logger;
use OpenTelemetry\API\Globals;
use OpenTelemetry\Contrib\Logs\Monolog\Handler;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Log\LogLevel;
use Slim\Factory\AppFactory;

require __DIR__ . '/../vendor/autoload.php';

$loggerProvider = Globals::loggerProvider();
$handler = new Handler(
    $loggerProvider,
    LogLevel::INFO
);
$monolog = new Logger('otel-php-monolog', [$handler]);

$app = AppFactory::create();

// Example route to show a basic trace
$app->get('/rolldice', function (Request $request, Response $response) use ($monolog) {
    $result = random_int(1,6);
    $response->getBody()->write(strval($result));
    $monolog->info('dice rolled', ['result' => $result]);
    return $response;
});

// Health check route, used by App Runner
$app->get('/health', function (Request $request, Response $response) {
    $response->getBody()->write('OK');
    return $response;
});

// Example route to demonstrate a simple welcome message
$app->get('/', function (Request $request, Response $response) {
    $response->getBody()->write('Welcome to the PHP Demo App Runner!');
    return $response;
});

// Example route to fetch data from an external API
$app->get('/fetch', function (Request $request, Response $response) use ($monolog) {
    $url = 'https://jsonplaceholder.typicode.com/posts/1';
    $client = new \GuzzleHttp\Client();
    try {
        $res = $client->get($url);
        $data = json_decode($res->getBody(), true);
        $response->getBody()->write(json_encode($data));
        $monolog->info('fetched data', ['url' => $url, 'data' => $data]);
        return $response->withHeader('Content-Type', 'application/json');
    } catch (\Exception $e) {
        $monolog->error('fetch failed', ['url' => $url, 'error' => $e->getMessage()]);
        $response->getBody()->write('Error fetching data');
        return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
    }
    return $response;
});

// Endpoint to fetch users from the database
$app->get('/users', function (Request $request, Response $response) use ($monolog) {
    try {
        $db = new Database();
        $users = $db->getUsers();
        
        $response->getBody()->write(json_encode($users));
        $monolog->info('users fetched', ['count' => count($users)]);
        return $response->withHeader('Content-Type', 'application/json');
    } catch (\Exception $e) {
        $monolog->error('database error', ['error' => $e->getMessage()]);
        $response->getBody()->write(json_encode(['error' => 'Failed to fetch users']));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
    }
});

$app->run();
