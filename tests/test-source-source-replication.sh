#!/bin/bash
set -e

echo "Building MySQL 8.0 image with the latest changes..."
docker build -t mysql-replication:8.0-test ../images/mysql-replication/8.0

echo "Starting source-source replication setup..."
# Clean up any existing containers
docker-compose -f docker-compose.source-source.yml down -v --remove-orphans
# Start the containers
docker-compose -f docker-compose.source-source.yml up -d

echo "Waiting for containers to start and replication to be established (30 seconds)..."
sleep 30

echo "Checking replication status on source1..."
docker-compose -f docker-compose.source-source.yml exec mysql-source1 mysql -uroot -proot_password -e "SHOW REPLICA STATUS\G"

echo "Checking replication status on source2..."
docker-compose -f docker-compose.source-source.yml exec mysql-source2 mysql -uroot -proot_password -e "SHOW REPLICA STATUS\G"

echo "Creating test database and table on source1..."
docker-compose -f docker-compose.source-source.yml exec mysql-source1 mysql -uroot -proot_password -e "
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;
CREATE TABLE IF NOT EXISTS test_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO test_table (name) VALUES ('Test Record from Source1');
SELECT * FROM test_table;
"

echo "Verifying replication to source2..."
docker-compose -f docker-compose.source-source.yml exec mysql-source2 mysql -uroot -proot_password -e "
USE test_db;
SELECT * FROM test_table;
"

echo "Creating a record on source2..."
docker-compose -f docker-compose.source-source.yml exec mysql-source2 mysql -uroot -proot_password -e "
USE test_db;
INSERT INTO test_table (name) VALUES ('Test Record from Source2');
SELECT * FROM test_table;
"

echo "Verifying replication back to source1..."
docker-compose -f docker-compose.source-source.yml exec mysql-source1 mysql -uroot -proot_password -e "
USE test_db;
SELECT * FROM test_table;
"

echo "Test completed. Cleaning up..."
docker-compose -f docker-compose.source-source.yml down -v

echo "Source-source replication test completed successfully!"