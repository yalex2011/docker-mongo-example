#!/bin/bash

mhost=$(mongo --quiet --eval 'rs.isMaster().primary' --host mongo_mongodb1 --port 27017 | grep  -oE '\mongo_mongodb[1-3]')

echo "=> Restore database $1 from $2"
if mongorestore --drop --db $1 --host $mhost --port 27017  $2; then
    echo "   Restore succeeded"
else
    echo "   Restore failed"
fi
echo "=> Done"
