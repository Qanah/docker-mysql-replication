# Docker MySQL Replication

This repository contains Docker images for MySQL replication setup, allowing you to easily create master-slave replication configurations.

## MySQL Replication Images

The MySQL replication images are available in two versions:

1. MySQL 5.7 - Traditional master-slave replication
2. MySQL 8.0 - Modern source-replica replication with improved features

Both versions are configured to support replication setups.

### Platform Support

- MySQL 5.7 image: Supports linux/amd64 architecture only
- MySQL 8.0 image: Supports both linux/amd64 and linux/arm64 architectures

### Environment Variables

The following environment variables can be used to configure the MySQL replication:

| Variable | Description | Default Value |
|----------|-------------|---------------|
| REPLICATION_USER | Username for replication | replication |
| REPLICATION_PASSWORD | Password for replication user | replication_pass |
| REPLICATION_SERVER_ID | Server ID for replication | 1 |
| REPLICATION_SERVER | Server role (master or slave) | (determined by REPLICATION_SERVER_ID) |
| MASTER_HOST | Hostname of the master server | (not set) |
| MASTER_PORT | Port of the master server | (MySQL default) |

### Server Configuration

#### MySQL 5.7
The server role is determined by the following rules (in order of precedence):

1. If `REPLICATION_SERVER=master`, the server will be configured as a master
2. If `REPLICATION_SERVER=slave`, the server will be configured as a slave (requires `MASTER_HOST` to be set)
3. If `REPLICATION_SERVER` is not set:
   - If `REPLICATION_SERVER_ID=1`, the server will be configured as a master
   - If `REPLICATION_SERVER_ID` is not 1 and `MASTER_HOST` is set, the server will be configured as a slave
   - Otherwise, the server will be configured as a standalone instance

#### MySQL 8.0
The server role is determined by the following rules (in order of precedence):

1. If `REPLICATION_SERVER=master`, the server will be configured as a source (master)
2. If `REPLICATION_SERVER=slave`, the server will be configured as a replica (slave) (requires `MASTER_HOST` to be set)
3. If `REPLICATION_SERVER` is not set:
   - If `REPLICATION_SERVER_ID=1`, the server will be configured as a source (master)
   - If `REPLICATION_SERVER_ID` is not 1 and `MASTER_HOST` is set, the server will be configured as a replica (slave)
   - Otherwise, the server will be configured as a standalone instance

Note: MySQL 8.0 uses the terms "source" and "replica" instead of "master" and "slave", but the environment variables `MASTER_HOST` and `REPLICATION_SERVER` (with values "master"/"slave") are kept for backward compatibility.

#### Master-Master (Source-Source) Replication
For master-master replication, set `REPLICATION_SERVER=master` for both servers and also set `MASTER_HOST` to point to the other server. This will configure each server as both a master and a slave.

### Example Usage

Several example configurations are provided in the `examples` directory:

#### Basic Master-Slave Setup (MySQL 5.7)

See [docker-compose.master-slave.yml](examples/docker-compose.master-slave.yml)

#### Basic Source-Replica Setup (MySQL 8.0)

See [docker-compose.source-replica.yml](examples/docker-compose.source-replica.yml)

#### Master-Master Replication (MySQL 5.7)

See [docker-compose.master-master.yml](examples/docker-compose.master-master.yml)

#### Source-Source Replication (MySQL 8.0)

See [docker-compose.source-source.yml](examples/docker-compose.source-source.yml)

#### Multi-Slave Configuration (MySQL 5.7)

See [docker-compose.multi-slave.yml](examples/docker-compose.multi-slave.yml)

### Testing Replication

To test that replication is working correctly, you can use the provided test setup:

1. Navigate to the tests directory:
   ```bash
   cd tests
   ```

2. Start the test replication setup:
   ```bash
   docker-compose -f docker-compose.test-replication.yml up -d
   ```

3. Wait for the containers to start and replication to be established (usually takes about 30 seconds).

4. Connect to the master database and insert some data:
   ```bash
   docker exec -it tests_mysql-master_1 mysql -uroot -proot_password
   ```

   ```sql
   USE test_db;
   INSERT INTO test_table (name) VALUES ('New Record from Master');
   SELECT * FROM test_table;
   EXIT;
   ```

5. Connect to the slave database and verify that the data has been replicated:
   ```bash
   docker exec -it tests_mysql-slave_1 mysql -uroot -proot_password
   ```

   ```sql
   USE test_db;
   SELECT * FROM test_table;
   EXIT;
   ```

   You should see the same records on the slave as on the master, including the new record you just inserted.

6. To test that changes on the slave are not allowed (read-only mode):
   ```bash
   docker exec -it tests_mysql-slave_1 mysql -uroot -proot_password
   ```

   ```sql
   USE test_db;
   INSERT INTO test_table (name) VALUES ('This should fail');
   EXIT;
   ```

   This should fail with an error message indicating that the slave is read-only.

7. Clean up when you're done:
   ```bash
   docker-compose -f docker-compose.test-replication.yml down -v
   ```

Alternatively, you can use the provided test script to test source-source replication:

```bash
cd tests
./test-source-source-replication.sh
```

This script will build a test image, start the containers, and run a series of tests to verify that replication is working correctly in both directions.

### Monitoring Replication Status

To check the status of replication and ensure it's working correctly, you can use the following commands:

#### MySQL 5.7 (Master-Slave)

1. Connect to the slave server:
   ```bash
   docker exec -it <container_name> mysql -uroot -p<password>
   ```

2. Check the replication status:
   ```sql
   SHOW SLAVE STATUS\G
   ```

   Key indicators to look for:
   - `Slave_IO_Running: Yes` - Indicates that the slave is connected to the master and receiving binary log events
   - `Slave_SQL_Running: Yes` - Indicates that the slave is applying the received events
   - `Seconds_Behind_Master: 0` (or a low number) - Indicates how far behind the slave is in processing updates
   - `Last_Error: ` - Should be empty; if not, it shows the last error that caused replication to stop

#### MySQL 8.0 (Source-Replica)

1. Connect to the replica server:
   ```bash
   docker exec -it <container_name> mysql -uroot -p<password>
   ```

2. Check the replication status:
   ```sql
   SHOW REPLICA STATUS\G
   ```

   Key indicators to look for:
   - `Replica_IO_Running: Yes` - Indicates that the replica is connected to the source and receiving binary log events
   - `Replica_SQL_Running: Yes` - Indicates that the replica is applying the received events
   - `Seconds_Behind_Source: 0` (or a low number) - Indicates how far behind the replica is in processing updates
   - `Last_Error: ` - Should be empty; if not, it shows the last error that caused replication to stop

#### Troubleshooting Replication Issues

If replication is not working correctly, check the following:

1. Ensure the master/source server is running and accessible from the slave/replica
2. Verify that the replication user has the correct permissions
3. Check for any errors in the replication status output
4. Restart replication if needed:
   ```sql
   -- MySQL 5.7
   STOP SLAVE;
   START SLAVE;

   -- MySQL 8.0
   STOP REPLICA;
   START REPLICA;
   ```

## CI/CD Pipeline

This repository includes a GitHub Actions workflow that builds and pushes the Docker images to Docker Hub when a new tag is pushed.

### Creating a New Release

To create a new release and trigger the CI/CD pipeline:

```bash
git tag v1.0.0
git push origin v1.0.0
```
