<?php

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

$app->get('/rolldice', function (Request $request, Response $response) use ($monolog) {
    $result = random_int(1,6);
    $response->getBody()->write(strval($result));
    $monolog->info('dice rolled', ['result' => $result]);
    return $response;
});

$app->get('/health', function (Request $request, Response $response) {
    $response->getBody()->write('OK');
    return $response;
});

$app->run();
