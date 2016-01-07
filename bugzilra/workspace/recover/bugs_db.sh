#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage : $0 backupfile (tar.gz) "
    exit 1
fi


find . -name "bugs.*.tar.gz" | tail -n 1  

# docker alias
DOCK='sudo docker'

# centos7 + httpd + mysql4  TODO : write to README 
IMAGE="bug1.2"
CONTAINER_NAME="bugzilra"

# generate docker container from image 
DOCK run -i -t --name="$CONTAINER_NAME" -h="$CONTAINER_NAME" -d bin/bash

# copy recovery data to container 
DOCK exec mkdir $CONTAINER_NAME:/root/recover
DOCK cp $TARGET $CONTAINER_NAME:/root/recover  

DOCK exec $CONTAINER_NAME  $MYSQL_HOME/bin/mysql -u bugs --password='bugs' -e "CREATE DATABASE bugs;"
DOCK exec $CONTAINER_NAME  $MYSQL_HOME/bin/mysql -u bugs -p bugs --password="bugs" < bugs.db

DOCK exec  $CONTAINER_NAME $MYSQL_HOME/bin/mysql -u bugs2 --password='bugs' -e "CREATE DATABASE bugs2;"
$CONTAINER_NAME -u bugs2 -p bugs2 --password="bugs" < bugs2.db
