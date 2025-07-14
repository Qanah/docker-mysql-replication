-- Create a test database
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;

-- Create a test table
CREATE TABLE IF NOT EXISTS test_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert some test data
INSERT INTO test_table (name) VALUES 
    ('Test Record 1'),
    ('Test Record 2'),
    ('Test Record 3');

-- Create a user for testing
CREATE USER IF NOT EXISTS 'test_user'@'%' IDENTIFIED BY 'test_password';
GRANT ALL PRIVILEGES ON test_db.* TO 'test_user'@'%';
FLUSH PRIVILEGES;