USE my_database;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES
('Alice Johnson', 'alice.j@example.com'),
('Bob Williams', 'bob.w@example.com'),
('Charlie Brown', 'charlie.b@example.com'),
('Diana Prince', 'diana.p@example.com');
