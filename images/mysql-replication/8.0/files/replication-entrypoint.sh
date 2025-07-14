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

# If SERVER_ID is 1, configure as master
if [ "$SERVER_ID" = "1" ]; then
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
# If SERVER_ID is not 1 and MASTER_HOST is set, configure as slave
elif [ ! -z "$MASTER_HOST" ]; then
  cp -v /init-slave.sh /docker-entrypoint-initdb.d/
  cat > /etc/mysql/conf.d/repl-slave.cnf << EOF
[mysqld]
log_replica_updates=ON
replica_parallel_workers=4
replica_preserve_commit_order=ON
EOF
# If SERVER_ID is not 1 but MASTER_HOST is not set, warn user
else
  echo "WARNING: REPLICATION_SERVER_ID is not 1, but MASTER_HOST is not set."
  echo "The server will be configured as a standalone instance."
  echo "To configure as a slave, set MASTER_HOST environment variable."
fi

cat > /etc/mysql/conf.d/server-id.cnf << EOF
[mysqld]
server-id=$SERVER_ID
EOF

exec docker-entrypoint.sh "$@"