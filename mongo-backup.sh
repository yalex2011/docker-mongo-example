#!/bin/bash
# debina/ubuntu need: apt install mongodb-tools
# centos/rhl need: yum install mongodb

# Binary path #
#MONGO="/usr/bin/mongo"
MONGODUMP="/usr/bin/mongodump"

# config #
BACKUPDIR="/home/backup/mongoDB"
HOST="172.16.77.2"
POST="27017"

$MONGODUMP --host $HOST  --port $PORT --db  --out $BACKUPDIR/$(date +"%d-%b-%Y")

# Delete files older than 7 days
find $BACKUPDIR/* -mtime +7 -exec rm {} \;