# Elastic APM Stack with PHP and Node.js

A complete Application Performance Monitoring (APM) stack using Elasticsearch, Kibana, APM Server, Logstash, with PHP-FPM and Node.js applications.

## 🏗️ Architecture

This stack includes:

- **Elasticsearch**: Data storage and search engine
- **Kibana**: Data visualization and APM UI
- **APM Server**: Collects and processes APM data
- **Logstash**: Log collection and processing
- **PHP-FPM**: PHP application with APM instrumentation
- **Nginx**: Web server for PHP application
- **Node.js**: Node application with APM instrumentation

## 🚀 Quick Start

### Prerequisites

- Docker
- Docker Compose

### 1. Start the Stack

```bash
# Clean start (recommended)
docker-compose down -v
docker-compose --profile setup up -d
docker-compose up --build
```

### 2. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Kibana | http://localhost:5601 | elastic:elastic123 |
| Elasticsearch | http://localhost:9200 | elastic:elastic123 |
| PHP App | http://localhost:8080 | - |
| Node App | http://localhost:3000 | - |
| APM Server | http://localhost:8200 | - |
| Logstash | http://localhost:5044 | - |

## 📊 Monitoring Features

### APM Monitoring

Both PHP and Node.js applications are instrumented with Elastic APM:

- **Performance metrics**: Response times, throughput, error rates
- **Distributed tracing**: Request flow across services
- **Error tracking**: Automatic error capture and stack traces
- **Database monitoring**: Query performance and slow queries

### Log Collection

Logstash collects and processes logs from:

- **PHP-FPM logs**: Process and error logs
- **Application logs**: Custom application logging
- **Error logs**: PHP errors and warnings

### Data Storage

- **APM data**: Stored in `apm-*` indices
- **Log data**: Stored in `php-logs-YYYY.MM.dd` indices

## 🔧 Configuration

### Environment Variables

#### Elasticsearch
- `ELASTIC_PASSWORD`: Master password (default: elastic123)
- `ES_JAVA_OPTS`: JVM settings (default: -Xms512m -Xmx512m)

#### Kibana
- `ELASTICSEARCH_USERNAME`: Service account (kibana_system)
- `ELASTICSEARCH_PASSWORD`: Service password (kibana123)

#### APM Applications
- `ELASTIC_APM_SERVER_URL`: APM server endpoint
- `ELASTIC_APM_SERVICE_NAME`: Service identifier
- `ELASTIC_APM_ENVIRONMENT`: Environment (production)

### PHP Configuration

The PHP application includes:
- **Elastic APM extension**: Native PHP APM agent
- **Error logging**: Configured to log to shared volume
- **Sample endpoints**: Health check and error generation

### Node.js Configuration

The Node.js application includes:
- **elastic-apm-node**: Official Node.js APM agent
- **Express framework**: Web server with APM instrumentation
- **Automatic instrumentation**: HTTP requests, database queries

## 📁 Directory Structure

```
apm/
├── docker-compose.yml          # Main compose file
├── README.md                   # This file
├── logstash/
│   ├── config/
│   │   └── logstash.yml       # Logstash configuration
│   └── pipeline/
│       └── php-logs.conf      # Log processing pipeline
├── nginx/
│   └── nginx.conf             # Nginx configuration for PHP
├── node/
│   ├── Dockerfile             # Node.js container
│   ├── package.json           # Node.js dependencies
│   └── index.js               # Node.js application
└── php/
    ├── Dockerfile             # PHP-FPM container
    └── index.php              # PHP application
```

## 🛠️ Development

### Adding Custom Logs

#### PHP Logging
```php
// Error logging
error_log("Custom log message");

// Trigger errors for testing
trigger_error("Test error", E_USER_WARNING);
```

#### Node.js Logging
```javascript
// Using built-in console (automatically captured)
console.log("Application log");
console.error("Error log");
```

### Testing APM Features

#### Generate PHP Errors
```bash
curl "http://localhost:8080?error=1"
```

#### Monitor Node.js Performance
```bash
curl "http://localhost:3000"
```

### Viewing Data in Kibana

1. **APM Data**:
   - Navigate to APM section in Kibana
   - View services: `php-app` and `node-app`
   - Analyze performance metrics and traces

2. **Log Data**:
   - Go to Discover section
   - Create index pattern: `php-logs-*`
   - Explore structured log data

## 🔍 Troubleshooting

### Common Issues

#### Elasticsearch Won't Start
```bash
# Check available memory
docker stats

# Reduce memory if needed (edit docker-compose.yml)
ES_JAVA_OPTS: "-Xms256m -Xmx256m"
```

#### Kibana Authentication Issues
```bash
# Reset setup
docker-compose down -v
docker-compose --profile setup up -d
```

#### PHP APM Extension Not Loading
```bash
# Check extension status
curl http://localhost:8080

# Rebuild PHP container
docker-compose build php-fpm
```

### Viewing Logs

```bash
# All services
docker-compose logs

# Specific service
docker-compose logs elasticsearch
docker-compose logs kibana
docker-compose logs php-fpm
```

### Container Health

```bash
# Check container status
docker-compose ps

# Check Elasticsearch health
curl -u elastic:elastic123 http://localhost:9200/_cluster/health
```

## 🧹 Cleanup

### Stop Services
```bash
docker-compose down
```

### Remove All Data
```bash
docker-compose down -v
```

### Full Cleanup
```bash
docker-compose down -v
docker system prune -f
docker network prune -f
```

## 📈 Performance Tuning

### Elasticsearch
- Adjust heap size based on available memory
- Use SSD storage for better performance
- Monitor cluster health regularly

### APM Data Retention
- Configure index lifecycle policies
- Set appropriate data retention periods
- Monitor storage usage

### Log Processing
- Optimize Logstash pipelines for high throughput
- Use appropriate batch sizes
- Monitor processing latency

## 🔒 Security Notes

- Change default passwords in production
- Use proper authentication mechanisms
- Configure network security groups
- Enable TLS/SSL for external access
- Regularly update container images

## 📚 Additional Resources

- [Elastic APM Documentation](https://www.elastic.co/guide/en/apm/index.html)
- [PHP APM Agent](https://www.elastic.co/guide/en/apm/agent/php/current/index.html)
- [Node.js APM Agent](https://www.elastic.co/guide/en/apm/agent/nodejs/current/index.html)
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)