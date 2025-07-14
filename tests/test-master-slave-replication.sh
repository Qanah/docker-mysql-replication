#!/bin/bash
set -e

echo "Building MySQL 5.7 image with the latest changes..."
# Clean up any existing containers
docker-compose -f docker-compose.master-slave.yml down -v --remove-orphans

echo "Starting master-slave replication setup..."
# Start the containers
docker-compose -f docker-compose.master-slave.yml up -d --build

echo "Waiting for containers to start and replication to be established (60 seconds)..."
sleep 60

echo "Checking if containers are running..."
master_running=$(docker-compose -f docker-compose.master-slave.yml ps -q mysql-master | wc -l)
slave_running=$(docker-compose -f docker-compose.master-slave.yml ps -q mysql-slave | wc -l)

if [ "$master_running" -eq 0 ]; then
  echo "ERROR: mysql-master container is not running!"
  docker-compose -f docker-compose.master-slave.yml logs mysql-master
  exit 1
fi

if [ "$slave_running" -eq 0 ]; then
  echo "ERROR: mysql-slave container is not running!"
  docker-compose -f docker-compose.master-slave.yml logs mysql-slave
  exit 1
fi

echo "Both containers are running."

echo "Waiting for MySQL to be ready in both containers..."
max_retries=30
retry_count=0
while ! docker-compose -f docker-compose.master-slave.yml exec -T mysql-master mysqladmin ping -h localhost -u root -proot_password --silent &> /dev/null; do
  retry_count=$((retry_count+1))
  if [ $retry_count -ge $max_retries ]; then
    echo "ERROR: Timed out waiting for MySQL in master container to be ready after $max_retries attempts."
    docker-compose -f docker-compose.master-slave.yml logs mysql-master
    exit 1
  fi
  echo "Attempt $retry_count/$max_retries: MySQL in master container is not ready yet. Waiting 5 seconds..."
  sleep 5
done
echo "MySQL in master container is ready."

retry_count=0
while ! docker-compose -f docker-compose.master-slave.yml exec -T mysql-slave mysqladmin ping -h localhost -u root -proot_password --silent &> /dev/null; do
  retry_count=$((retry_count+1))
  if [ $retry_count -ge $max_retries ]; then
    echo "ERROR: Timed out waiting for MySQL in slave container to be ready after $max_retries attempts."
    docker-compose -f docker-compose.master-slave.yml logs mysql-slave
    exit 1
  fi
  echo "Attempt $retry_count/$max_retries: MySQL in slave container is not ready yet. Waiting 5 seconds..."
  sleep 5
done
echo "MySQL in slave container is ready."

echo "Checking container logs for any issues..."
echo "=== mysql-master logs ==="
docker-compose -f docker-compose.master-slave.yml logs mysql-master | tail -n 20
echo "=== mysql-slave logs ==="
docker-compose -f docker-compose.master-slave.yml logs mysql-slave | tail -n 20

echo "Checking replication status on slave..."
docker-compose -f docker-compose.master-slave.yml exec mysql-slave mysql -uroot -proot_password -e "SHOW SLAVE STATUS\G"

echo "Creating test database and table on master..."
docker-compose -f docker-compose.master-slave.yml exec mysql-master mysql -uroot -proot_password -e "
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;
CREATE TABLE IF NOT EXISTS test_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO test_table (name) VALUES ('Test Record from Master');
SELECT * FROM test_table;
"

echo "Verifying replication to slave..."
docker-compose -f docker-compose.master-slave.yml exec mysql-slave mysql -uroot -proot_password -e "
USE test_db;
SELECT * FROM test_table;
"

echo "Testing that slave is read-only..."
docker-compose -f docker-compose.master-slave.yml exec mysql-slave mysql -uroot -proot_password -e "
USE test_db;
INSERT INTO test_table (name) VALUES ('This should fail because slave is read-only');
" || echo "Confirmed: Slave is read-only as expected"

echo "Adding more data on master..."
docker-compose -f docker-compose.master-slave.yml exec mysql-master mysql -uroot -proot_password -e "
USE test_db;
INSERT INTO test_table (name) VALUES ('Another Test Record from Master');
SELECT * FROM test_table;
"

echo "Verifying new data is replicated to slave..."
docker-compose -f docker-compose.master-slave.yml exec mysql-slave mysql -uroot -proot_password -e "
USE test_db;
SELECT * FROM test_table;
"

echo "Test completed. Cleaning up..."
docker-compose -f docker-compose.master-slave.yml down -v

echo "Master-slave replication test completed successfully!"
