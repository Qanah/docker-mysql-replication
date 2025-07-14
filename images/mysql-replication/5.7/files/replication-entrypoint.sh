#!/bin/bash
set -eo pipefail

cat > /etc/mysql/mysql.conf.d/repl.cnf << EOF
[mysqld]
log-bin=mysql-bin
relay-log=mysql-relay
expire-logs-days=14
#bind-address=0.0.0.0
#skip-name-resolve
innodb_file_per_table = 1
innodb_flush_method = O_DIRECT
innodb-flush-log-at-trx-commit = 0
transaction-isolation = READ-COMMITTED
max_allowed_packet = 128M
# Enable GTID mode
gtid_mode=ON
enforce_gtid_consistency=ON
EOF

# Use REPLICATION_SERVER_ID from environment variable
export SERVER_ID=${REPLICATION_SERVER_ID:-1}
export REPLICATION_SERVER=${REPLICATION_SERVER:-}

# If REPLICATION_SERVER is set to "master" and MASTER_HOST is set, configure as both master and slave
if [ "$REPLICATION_SERVER" = "master" ] && [ ! -z "$MASTER_HOST" ]; then
  # Configure as master
  cat >/docker-entrypoint-initdb.d/init-master.sh  <<'EOF'
#!/bin/bash

echo Creating replication user ...
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "\
  GRANT \
    FILE, \
    SELECT, \
    SHOW VIEW, \
    LOCK TABLES, \
    RELOAD, \
    REPLICATION SLAVE, \
    REPLICATION CLIENT \
  ON *.* \
  TO '$REPLICATION_USER'@'%' \
  IDENTIFIED BY '$REPLICATION_PASSWORD'; \
  FLUSH PRIVILEGES; \
"
EOF
  # Also configure as slave
  cp -v /init-slave.sh /docker-entrypoint-initdb.d/
  cat > /etc/mysql/mysql.conf.d/repl-slave.cnf << EOF
[mysqld]
log-slave-updates
master-info-repository=TABLE
relay-log-info-repository=TABLE
relay-log-recovery=1
EOF
# If REPLICATION_SERVER is set to "master" or SERVER_ID is 1 and REPLICATION_SERVER is not "slave", configure as master only
elif [ "$REPLICATION_SERVER" = "master" ] || ([ "$SERVER_ID" = "1" ] && [ "$REPLICATION_SERVER" != "slave" ]); then
  cat >/docker-entrypoint-initdb.d/init-master.sh  <<'EOF'
#!/bin/bash

echo Creating replication user ...
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "\
  GRANT \
    FILE, \
    SELECT, \
    SHOW VIEW, \
    LOCK TABLES, \
    RELOAD, \
    REPLICATION SLAVE, \
    REPLICATION CLIENT \
  ON *.* \
  TO '$REPLICATION_USER'@'%' \
  IDENTIFIED BY '$REPLICATION_PASSWORD'; \
  FLUSH PRIVILEGES; \
"
EOF
# If REPLICATION_SERVER is set to "slave" or (SERVER_ID is not 1 and MASTER_HOST is set), configure as slave
elif [ "$REPLICATION_SERVER" = "slave" ] || ([ "$SERVER_ID" != "1" ] && [ ! -z "$MASTER_HOST" ]); then
  cp -v /init-slave.sh /docker-entrypoint-initdb.d/
  cat > /etc/mysql/mysql.conf.d/repl-slave.cnf << EOF
[mysqld]
log-slave-updates
master-info-repository=TABLE
relay-log-info-repository=TABLE
relay-log-recovery=1
EOF
# If neither master nor slave configuration is triggered, warn user
else
  echo "WARNING: Server not configured as master or slave."
  echo "The server will be configured as a standalone instance."
  echo "To configure as a master, set REPLICATION_SERVER=master or use REPLICATION_SERVER_ID=1."
  echo "To configure as a slave, set REPLICATION_SERVER=slave or set MASTER_HOST environment variable."
fi

cat > /etc/mysql/mysql.conf.d/server-id.cnf << EOF
[mysqld]
server-id=$SERVER_ID
EOF

exec docker-entrypoint.sh "$@"
