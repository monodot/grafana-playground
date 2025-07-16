<?php

namespace App;

class Database
{
    private $pdo;

    public function __construct()
    {
        $host = getenv('MYSQL_HOST') ?: 'db';
        $dbname = getenv('MYSQL_DATABASE') ?: 'my_database';
        $user = getenv('MYSQL_USER') ?: 'user';
        $pass = getenv('MYSQL_PASSWORD') ?: 'password';

        $dsn = "mysql:host=$host;dbname=$dbname;charset=utf8mb4";
        
        $options = [
            \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
            \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
            \PDO::ATTR_EMULATE_PREPARES => false,
        ];

        try {
            $this->pdo = new \PDO($dsn, $user, $pass, $options);
        } catch (\PDOException $e) {
            throw new \PDOException($e->getMessage(), (int)$e->getCode());
        }
    }

    public function getUsers()
    {
        $stmt = $this->pdo->query('SELECT * FROM users');
        return $stmt->fetchAll();
    }
}
