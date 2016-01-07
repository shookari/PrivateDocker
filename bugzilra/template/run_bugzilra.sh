#!/bin/bash

/root/mysql_script/mysql_start
sleep 3
apachectl -k start
