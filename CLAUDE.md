# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Building and Testing
```bash
# Test MySQL 5.7 master-slave replication
cd tests/5.7
./test-master-slave-replication.sh

# Test MySQL 8.0 source-replica replication
cd tests/8.0
./test-source-replica-replication.sh

# Test MySQL 8.0 source-source bidirectional replication
cd tests/8.0
./test-source-source-replication.sh
```

### Running Examples
```bash
# Start MySQL 5.7 master-slave setup
cd examples/5.7
docker-compose -f docker-compose.master-slave.yml up -d

# Start MySQL 8.0 source-replica setup
cd examples/8.0
docker-compose -f docker-compose.source-replica.yml up -d

# Clean up any setup
docker-compose -f <compose-file> down -v
```

### Building Docker Images
```bash
# Build MySQL 5.7 image
cd images/mysql-replication/5.7
docker build -t qanah/mysql-replication:5.7-latest .

# Build MySQL 8.0 image
cd images/mysql-replication/8.0
docker build -t qanah/mysql-replication:8.0-latest .
```

## Architecture Overview

This repository provides Docker images and configurations for MySQL replication setups. The architecture consists of:

### Core Components
- **Custom MySQL Images**: Based on official MySQL images with replication configuration scripts
- **Replication Entrypoint Scripts**: Handle automatic master/slave or source/replica configuration
- **Example Configurations**: Pre-built docker-compose files for common replication patterns
- **Test Framework**: Automated testing scripts that verify replication functionality

### MySQL Versions and Terminology
- **MySQL 5.7**: Uses traditional "master-slave" terminology
- **MySQL 8.0**: Uses modern "source-replica" terminology for the same functionality

### Replication Configuration Logic
Server roles are determined by environment variables in this precedence:
1. `REPLICATION_SERVER` (master/slave) - explicit role assignment
2. `REPLICATION_SERVER_ID=1` + no `MASTER_HOST` = master/source
3. `REPLICATION_SERVER_ID≠1` + `MASTER_HOST` set = slave/replica
4. Otherwise = standalone instance

### Environment Variables
Key variables for configuring replication:
- `REPLICATION_USER/REPLICATION_PASSWORD`: Credentials for replication user
- `REPLICATION_SERVER_ID`: Unique server identifier
- `REPLICATION_SERVER`: Explicit role (master/slave)
- `MASTER_HOST`: Hostname of master/source server

### Platform Support
- MySQL 5.7: linux/amd64 only (Mac ARM requires platform specification)
- MySQL 8.0: Both linux/amd64 and linux/arm64

### Test Scripts
All test scripts follow the pattern:
1. Clean up existing containers
2. Build/start containers with docker-compose
3. Wait for MySQL readiness
4. Create test data on master/source
5. Verify replication to slave/replica
6. Test read-only constraints on slave/replica
7. Clean up containers

### File Structure
- `examples/`: Ready-to-use docker-compose configurations
- `images/mysql-replication/`: Dockerfiles and scripts for custom MySQL images
- `tests/`: Automated test scripts and test-specific compose files