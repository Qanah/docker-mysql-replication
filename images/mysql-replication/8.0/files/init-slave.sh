#!/bin/bash
# TODO: cover replica side selection for replication entities:
# * replicate-do-db=db_name only if we want to store and replicate certain DBs
# * replicate-ignore-db=db_name used when we don't want to replicate certain DBs
# * replicate_wild_do_table used to replicate tables based on wildcard patterns
# * replicate_wild_ignore_table used to ignore tables in replication based on wildcard patterns

REPLICATION_HEALTH_GRACE_PERIOD=${REPLICATION_HEALTH_GRACE_PERIOD:-3}
REPLICATION_HEALTH_TIMEOUT=${REPLICATION_HEALTH_TIMEOUT:-10}

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

echo mysqldump completed.

echo Starting replica ...
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "START REPLICA;"

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
