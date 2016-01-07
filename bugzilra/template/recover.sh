#!/bin/bash

PWD=`pwd`
RECOVER_DATA="$1"
tar -xvzf $RECOVER_DATA

UNTAR_DIR=`basename $RECOVER_DATA | awk -F "." '{print $2}'`
RECOVER_DB_PATH=$PWD/$UNTAR_DIR/db
RECOVER_CONTENTS_PATH=$PWD/$UNTAR_DIR/contents

useradd mysql
touch /tmp/mysql_bug.sock
mkdir -p /var/lib/mysql4 /var/log/mysql4 /var/run/mysql4/mysqld
chown -R mysql.mysql /var/lib/mysql4 /var/run/mysql4/mysqld /tmp/mysql_bug.sock

# Generate MySQL system database and table
$MYSQL_HOME/bin/mysql_install_db --defaults-file=$MYSQL_CONF --datadir=$MYSQL_DATA --user=mysql

# Mysql root password reset
/root/mysql_script/mysql_start
sleep 3
$MYSQL_HOME/bin/mysqladmin --defaults-file=$MYSQL_CONF -u root --password='bugs'

$MYSQL_HOME/bin/mysql -u root --password='bugs' -e "GRANT SELECT, INSERT, UPDATE, DELETE, INDEX, ALTER, CREATE, LOCK TABLES, CREATE TEMPORARY TABLES, DROP, REFERENCES ON bugs.* TO bugs@localhost IDENTIFIED BY 'bugs'; FLUSH PRIVILEGES;"

$MYSQL_HOME/bin/mysql -u root --password='bugs' -e "GRANT SELECT, INSERT, UPDATE, DELETE, INDEX, ALTER, CREATE, LOCK TABLES, CREATE TEMPORARY TABLES, DROP, REFERENCES ON bugs2.* TO bugs2@localhost IDENTIFIED BY 'bugs2'; FLUSH PRIVILEGES;"

# Bugzilra db recovery
$MYSQL_HOME/bin/mysql -u bugs --password='bugs' -e "CREATE DATABASE bugs;"
$MYSQL_HOME/bin/mysql -u bugs -p bugs --password="bugs" < $RECOVER_DB_PATH/bugs.db

$MYSQL_HOME/bin/mysql -u bugs2 --password='bugs2' -e "CREATE DATABASE bugs2;"
$MYSQL_HOME/bin/mysql -u bugs2 -p bugs2 --password="bugs2" < $RECOVER_DB_PATH/bugs2.db

# Bugzilra html(page) recovery
\cp -rf $RECOVER_CONTENTS_PATH/html /var/www/
chmod -R 755 /var/www/html


/root/mysql_script/mysql_stop
apachectl -k stop

exit 0
