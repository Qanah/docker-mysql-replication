# Docker MySQL Replication

This repository contains Docker images for MySQL replication setup, allowing you to easily create master-slave replication configurations.

## MySQL Replication Images

The MySQL replication images are available in two versions:

1. MySQL 5.7 - Traditional master-slave replication
2. MySQL 8.0 - Modern source-replica replication with improved features

Both versions are configured to support replication setups.

### Environment Variables

The following environment variables can be used to configure the MySQL replication:

| Variable | Description | Default Value |
|----------|-------------|---------------|
| REPLICATION_USER | Username for replication | replication |
| REPLICATION_PASSWORD | Password for replication user | replication_pass |
| REPLICATION_SERVER_ID | Server ID for replication | 1 |
| MASTER_HOST | Hostname of the master server | (not set) |
| MASTER_PORT | Port of the master server | (MySQL default) |

### Server Configuration

#### MySQL 5.7
- If `REPLICATION_SERVER_ID=1`, the server will be configured as a master
- If `REPLICATION_SERVER_ID` is not 1 (e.g., 2, 3, 4...) and `MASTER_HOST` is set, the server will be configured as a slave
- If `REPLICATION_SERVER_ID` is not 1 but `MASTER_HOST` is not set, the server will be configured as a standalone instance

#### MySQL 8.0
- If `REPLICATION_SERVER_ID=1`, the server will be configured as a source (master)
- If `REPLICATION_SERVER_ID` is not 1 (e.g., 2, 3, 4...) and `MASTER_HOST` is set, the server will be configured as a replica (slave)
- If `REPLICATION_SERVER_ID` is not 1 but `MASTER_HOST` is not set, the server will be configured as a standalone instance

Note: MySQL 8.0 uses the terms "source" and "replica" instead of "master" and "slave", but the environment variable `MASTER_HOST` is kept for backward compatibility.

### Example Usage

#### Docker Compose Example for MySQL 5.7

```yaml
version: '3'

services:
  mysql-master:
    image: your-dockerhub-username/mysql-replication:5.7-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=1
    ports:
      - "3306:3306"
    volumes:
      - mysql-master-data:/var/lib/mysql

  mysql-slave1:
    image: your-dockerhub-username/mysql-replication:5.7-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=2
      - MASTER_HOST=mysql-master
    ports:
      - "3307:3306"
    volumes:
      - mysql-slave1-data:/var/lib/mysql
    depends_on:
      - mysql-master

volumes:
  mysql-master-data:
  mysql-slave1-data:
```

#### Docker Compose Example for MySQL 8.0

```yaml
version: '3'

services:
  mysql-source:
    image: your-dockerhub-username/mysql-replication:latest  # or 8.0-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=1
    ports:
      - "3306:3306"
    volumes:
      - mysql-source-data:/var/lib/mysql

  mysql-replica1:
    image: your-dockerhub-username/mysql-replication:latest  # or 8.0-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=2
      - MASTER_HOST=mysql-source
    ports:
      - "3307:3306"
    volumes:
      - mysql-replica1-data:/var/lib/mysql
    depends_on:
      - mysql-source

volumes:
  mysql-source-data:
  mysql-replica1-data:
```

## CI/CD Pipeline

This repository includes a GitHub Actions workflow that builds and pushes the Docker images to Docker Hub when a new tag is pushed.

### Creating a New Release

To create a new release and trigger the CI/CD pipeline:

```bash
git tag v1.0.0
git push origin v1.0.0
```
