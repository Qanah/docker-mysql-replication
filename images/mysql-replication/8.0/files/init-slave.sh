#!/bin/bash
# TODO: cover replica side selection for replication entities:
# * replicate-do-db=db_name only if we want to store and replicate certain DBs
# * replicate-ignore-db=db_name used when we don't want to replicate certain DBs
# * replicate_wild_do_table used to replicate tables based on wildcard patterns
# * replicate_wild_ignore_table used to ignore tables in replication based on wildcard patterns

REPLICATION_HEALTH_GRACE_PERIOD=${REPLICATION_HEALTH_GRACE_PERIOD:-3}
REPLICATION_HEALTH_TIMEOUT=${REPLICATION_HEALTH_TIMEOUT:-10}
# Set default port if not specified
MASTER_PORT=${MASTER_PORT:-3306}

check_replica_health () {
  echo Checking replication health:
  status=$(mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SHOW REPLICA STATUS\G")
  echo "$status" | egrep 'Replica_(IO|SQL)_Running:|Seconds_Behind_Source:|Last_.*_Error:' | grep -v "Error: $"
  if ! echo "$status" | grep -qs "Replica_IO_Running: Yes"    ||
     ! echo "$status" | grep -qs "Replica_SQL_Running: Yes"   ||
     ! echo "$status" | grep -qs "Seconds_Behind_Source: 0" ; then
	echo WARNING: Replication is not healthy.
    return 1
  fi
  return 0
}


echo Updating source connection info in replica.

# Skip RESET MASTER if this server is also a source (for source-source replication)
if [ "$REPLICATION_SERVER" = "master" ]; then
  echo "This server is also configured as a source (master), skipping RESET MASTER..."
  mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "\
    CHANGE REPLICATION SOURCE TO \
    SOURCE_HOST='$MASTER_HOST', \
    SOURCE_PORT=$MASTER_PORT, \
    SOURCE_USER='$REPLICATION_USER', \
    SOURCE_PASSWORD='$REPLICATION_PASSWORD', \
    SOURCE_AUTO_POSITION=1;"
else
  mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "RESET MASTER; \
    CHANGE REPLICATION SOURCE TO \
    SOURCE_HOST='$MASTER_HOST', \
    SOURCE_PORT=$MASTER_PORT, \
    SOURCE_USER='$REPLICATION_USER', \
    SOURCE_PASSWORD='$REPLICATION_PASSWORD', \
    SOURCE_AUTO_POSITION=1;"
fi

# For source-source replication, we skip the mysqldump step to avoid deadlock
if [ "$REPLICATION_SERVER" = "master" ]; then
  echo "This is a source-source replication setup. Skipping mysqldump step to avoid deadlock."
else
  # Wait for the master to be ready
  echo "Waiting for $MASTER_HOST to be ready..."
  max_retries=30
  retry_count=0
  while ! mysqladmin ping -h"$MASTER_HOST" -P"$MASTER_PORT" -u"$REPLICATION_USER" -p"$REPLICATION_PASSWORD" --silent &> /dev/null; do
    retry_count=$((retry_count+1))
    if [ $retry_count -ge $max_retries ]; then
      echo "ERROR: Timed out waiting for $MASTER_HOST to be ready after $max_retries attempts."
      exit 1
    fi
    echo "Attempt $retry_count/$max_retries: $MASTER_HOST is not ready yet. Waiting 5 seconds..."
    sleep 5
  done
  echo "$MASTER_HOST is ready. Proceeding with replication setup."

  mysqldump \
    --protocol=tcp \
    --user=$REPLICATION_USER \
    --password=$REPLICATION_PASSWORD \
    --host=$MASTER_HOST \
    --port=$MASTER_PORT \
    --hex-blob \
    --all-databases \
    --add-drop-database \
    --source-data \
    --flush-logs \
    --flush-privileges \
    | mysql -uroot -p$MYSQL_ROOT_PASSWORD
fi

echo mysqldump completed.

echo Starting replica ...
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "START REPLICA;"

# For source-source replication, we need to be more lenient with health checks
if [ "$REPLICATION_SERVER" = "master" ]; then
  echo "This is a source-source replication setup. Skipping health checks to avoid issues."
  # Just wait a bit to let replication start
  sleep 10
else
  echo Initial health check:
  check_replica_health

  echo Waiting for health grace period and replica to be still healthy:
  sleep $REPLICATION_HEALTH_GRACE_PERIOD

  counter=0
  while ! check_replica_health; do
    if (( counter >= $REPLICATION_HEALTH_TIMEOUT )); then
      echo ERROR: Replication not healthy, health timeout reached, failing.
      break
      exit 1
    fi
    let counter=counter+1
    sleep 1
  done
fi
