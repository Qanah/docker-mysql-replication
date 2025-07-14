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

#### Basic Master-Slave Setup (MySQL 5.7)

```yaml
version: '3'

services:
  mysql-master:
    image: your-dockerhub-username/mysql-replication:5.7-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=1
      # Alternatively, you can use REPLICATION_SERVER=master
    ports:
      - "3306:3306"
    volumes:
      - mysql-master-data:/var/lib/mysql

  mysql-slave1:
    image: your-dockerhub-username/mysql-replication:5.7-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=2
      # Alternatively, you can use REPLICATION_SERVER=slave
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

#### Basic Source-Replica Setup (MySQL 8.0)

```yaml
version: '3'

services:
  mysql-source:
    image: your-dockerhub-username/mysql-replication:latest  # or 8.0-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=1
      # Alternatively, you can use REPLICATION_SERVER=master
    ports:
      - "3306:3306"
    volumes:
      - mysql-source-data:/var/lib/mysql

  mysql-replica1:
    image: your-dockerhub-username/mysql-replication:latest  # or 8.0-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=2
      # Alternatively, you can use REPLICATION_SERVER=slave
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

#### Master-Master Replication (MySQL 5.7)

```yaml
version: '3'

services:
  mysql-master1:
    image: your-dockerhub-username/mysql-replication:5.7-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=1
      - REPLICATION_SERVER=master
      - MASTER_HOST=mysql-master2
    ports:
      - "3306:3306"
    volumes:
      - mysql-master1-data:/var/lib/mysql

  mysql-master2:
    image: your-dockerhub-username/mysql-replication:5.7-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=2
      - REPLICATION_SERVER=master
      - MASTER_HOST=mysql-master1
    ports:
      - "3307:3306"
    volumes:
      - mysql-master2-data:/var/lib/mysql
    depends_on:
      - mysql-master1

volumes:
  mysql-master1-data:
  mysql-master2-data:
```

#### Source-Source Replication (MySQL 8.0)

```yaml
version: '3'

services:
  mysql-source1:
    image: your-dockerhub-username/mysql-replication:latest  # or 8.0-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=1
      - REPLICATION_SERVER=master
      - MASTER_HOST=mysql-source2
    ports:
      - "3306:3306"
    volumes:
      - mysql-source1-data:/var/lib/mysql

  mysql-source2:
    image: your-dockerhub-username/mysql-replication:latest  # or 8.0-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=2
      - REPLICATION_SERVER=master
      - MASTER_HOST=mysql-source1
    ports:
      - "3307:3306"
    volumes:
      - mysql-source2-data:/var/lib/mysql
    depends_on:
      - mysql-source1

volumes:
  mysql-source1-data:
  mysql-source2-data:
```

#### Multi-Slave Configuration (MySQL 5.7)

```yaml
version: '3'

services:
  mysql-master:
    image: your-dockerhub-username/mysql-replication:5.7-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER=master
    ports:
      - "3306:3306"
    volumes:
      - mysql-master-data:/var/lib/mysql

  mysql-slave1:
    image: your-dockerhub-username/mysql-replication:5.7-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=2
      - REPLICATION_SERVER=slave
      - MASTER_HOST=mysql-master
    ports:
      - "3307:3306"
    volumes:
      - mysql-slave1-data:/var/lib/mysql
    depends_on:
      - mysql-master

  mysql-slave2:
    image: your-dockerhub-username/mysql-replication:5.7-latest
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - REPLICATION_SERVER_ID=3
      - REPLICATION_SERVER=slave
      - MASTER_HOST=mysql-master
    ports:
      - "3308:3306"
    volumes:
      - mysql-slave2-data:/var/lib/mysql
    depends_on:
      - mysql-master

volumes:
  mysql-master-data:
  mysql-slave1-data:
  mysql-slave2-data:
```

## CI/CD Pipeline

This repository includes a GitHub Actions workflow that builds and pushes the Docker images to Docker Hub when a new tag is pushed.

### Creating a New Release

To create a new release and trigger the CI/CD pipeline:

```bash
git tag v1.0.0
git push origin v1.0.0
```
