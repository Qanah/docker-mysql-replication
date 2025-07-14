#!/bin/bash
set -e

echo "Starting source-replica replication setup..."
# Clean up any existing containers
docker-compose -f docker-compose.source-replica.yml down -v --remove-orphans
# Start the containers
docker-compose -f docker-compose.source-replica.yml up -d --build

echo "Waiting for containers to start and replication to be established (30 seconds)..."
sleep 30

echo "Checking replication status on replica..."
docker-compose -f docker-compose.source-replica.yml exec mysql-replica mysql -uroot -proot_password -e "SHOW REPLICA STATUS\G"

echo "Creating test database and table on source..."
docker-compose -f docker-compose.source-replica.yml exec mysql-source mysql -uroot -proot_password -e "
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;
CREATE TABLE IF NOT EXISTS test_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO test_table (name) VALUES ('Test Record from Source');
SELECT * FROM test_table;
"

echo "Verifying replication to replica..."
docker-compose -f docker-compose.source-replica.yml exec mysql-replica mysql -uroot -proot_password -e "
USE test_db;
SELECT * FROM test_table;
"

echo "Testing that replica is read-only..."
docker-compose -f docker-compose.source-replica.yml exec mysql-replica mysql -uroot -proot_password -e "
USE test_db;
INSERT INTO test_table (name) VALUES ('This should fail because replica is read-only');
" || echo "Confirmed: Replica is read-only as expected"

echo "Adding more data on source..."
docker-compose -f docker-compose.source-replica.yml exec mysql-source mysql -uroot -proot_password -e "
USE test_db;
INSERT INTO test_table (name) VALUES ('Another Test Record from Source');
SELECT * FROM test_table;
"

echo "Verifying new data is replicated to replica..."
docker-compose -f docker-compose.source-replica.yml exec mysql-replica mysql -uroot -proot_password -e "
USE test_db;
SELECT * FROM test_table;
"

echo "Test completed. Cleaning up..."
docker-compose -f docker-compose.source-replica.yml down -v

echo "Source-replica replication test completed successfully!"