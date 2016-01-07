#!/bin/bash

# NOTI : run by admin(root)
useradd mysql
touch /tmp/mysql_bug.sock
mkdir -p /var/lib/mysql4 /var/log/mysql4 /var/run/mysql4/mysqld
chown -R mysql.mysql /var/lib/mysql4 /var/run/mysql4/mysqld /tmp/mysql_bug.sock

# Generate MySQL system database and table
$MYSQL_HOME/bin/mysql_install_db --defaults-file=$MYSQL_CONF --datadir=$MYSQL_DATA --user=mysql

# Mysql root password reset
/root/mysql_script/mysql_start
sleep 3
$MYSQL_HOME/bin/mysqladmin --defaults-file=$MYSQL_CONF -u root password 'bugs'

$MYSQL_HOME/bin/mysql -u root --password='bugs' -e "GRANT SELECT, INSERT, UPDATE, DELETE, INDEX, ALTER, CREATE, LOCK TABLES, CREATE TEMPORARY TABLES, DROP, REFERENCES ON bugs.* TO bugs@localhost IDENTIFIED BY 'bugs'; FLUSH PRIVILEGES;"

$MYSQL_HOME/bin/mysql -u root --password='bugs' -e "GRANT SELECT, INSERT, UPDATE, DELETE, INDEX, ALTER, CREATE, LOCK TABLES, CREATE TEMPORARY TABLES, DROP, REFERENCES ON bugs2.* TO bugs2@localhost IDENTIFIED BY 'bugs2'; FLUSH PRIVILEGES;"

/root/mysql_script/mysql_stop
