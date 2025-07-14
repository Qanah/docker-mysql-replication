#!/bin/bash
set -eo pipefail

cat > /etc/mysql/conf.d/repl.cnf << EOF
[mysqld]
log-bin=mysql-bin
relay-log=mysql-relay
binlog_expire_logs_seconds=1209600
#bind-address=0.0.0.0
#skip-name-resolve
innodb_file_per_table = 1
innodb_flush_method = O_DIRECT
innodb_flush_log_at_trx_commit = 0
transaction_isolation = READ-COMMITTED
max_allowed_packet = 128M
default_authentication_plugin = mysql_native_password
EOF

# Use REPLICATION_SERVER_ID from environment variable
export SERVER_ID=${REPLICATION_SERVER_ID:-1}
export REPLICATION_SERVER=${REPLICATION_SERVER:-}

# If REPLICATION_SERVER is set to "master" or SERVER_ID is 1 and REPLICATION_SERVER is not "slave", configure as source (master)
if [ "$REPLICATION_SERVER" = "master" ] || ([ "$SERVER_ID" = "1" ] && [ "$REPLICATION_SERVER" != "slave" ]); then
  cat >/docker-entrypoint-initdb.d/init-master.sh  <<'EOF'
#!/bin/bash

echo Creating replication user ...
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "\
  CREATE USER IF NOT EXISTS '$REPLICATION_USER'@'%' IDENTIFIED WITH 'mysql_native_password' BY '$REPLICATION_PASSWORD'; \
  GRANT \
    FILE, \
    SELECT, \
    SHOW VIEW, \
    LOCK TABLES, \
    RELOAD, \
    REPLICATION SLAVE, \
    REPLICATION CLIENT \
  ON *.* \
  TO '$REPLICATION_USER'@'%'; \
  FLUSH PRIVILEGES; \
"
EOF
# If REPLICATION_SERVER is set to "slave" or (SERVER_ID is not 1 and MASTER_HOST is set), configure as replica (slave)
elif [ "$REPLICATION_SERVER" = "slave" ] || ([ "$SERVER_ID" != "1" ] && [ ! -z "$MASTER_HOST" ]); then
  cp -v /init-slave.sh /docker-entrypoint-initdb.d/
  cat > /etc/mysql/conf.d/repl-slave.cnf << EOF
[mysqld]
log_replica_updates=ON
replica_parallel_workers=4
replica_preserve_commit_order=ON
EOF
# If neither master nor slave configuration is triggered, warn user
else
  echo "WARNING: Server not configured as source (master) or replica (slave)."
  echo "The server will be configured as a standalone instance."
  echo "To configure as a source (master), set REPLICATION_SERVER=master or use REPLICATION_SERVER_ID=1."
  echo "To configure as a replica (slave), set REPLICATION_SERVER=slave or set MASTER_HOST environment variable."
fi

cat > /etc/mysql/conf.d/server-id.cnf << EOF
[mysqld]
server-id=$SERVER_ID
EOF

exec docker-entrypoint.sh "$@"
