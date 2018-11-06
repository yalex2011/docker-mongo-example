
#Запускаем Swarm cluster
echo "Запускаем Swarm cluster"
docker stack deploy -c mongo-deploy.yml mongo

sleep 30

# Запускаем репликацию
echo "Запускаем репликацию"
docker exec -it $(docker ps -qf name=mongo_mongodb1) mongo --eval 'rs.initiate({ _id: "example", members: [{ _id: 1, host: "mongo_mongodb1:27017" }, { _id: 2, host: "mongo_mongodb2:27017" }, { _id: 3, host: "mongo_mongodb3:27017" }], settings: { getLastErrorDefaults: { w: "majority", wtimeout: 30000 }}})'

sleep 10

# Проверка
echo "Проверка"
docker exec -it $(docker ps -qf name=mongo_mongodb1)  mongo --eval 'rs.status()'

# Запускуаем koalab service
#docker service create --env 'MONGO_URL=mongodb://mongo_mongodb1:27017,mongo_mongodb2:27017,mongo_mongodb3:27017/koalab?replicaSet=example' --name koalab --network mongo_mongonet --replicas 2 --publish 8080:8080 kalahari/koalab

# Check master in db cluster
docker exec -it $(docker ps -qf name=mongo_mongodb3) mongo --eval 'rs.isMaster().primary'


# docker exec -it $(docker ps -qf name=mongo_mongodb3) mongo --eval 'rs.isMaster().primary' | grep  -oE '\mongo_mongodb[1-3]'
# Stop master container
# docker stop $(docker ps -qf name=mongo_mongodb1)
# Определяем мастера и тушим контейнер с ним
docker stop $(docker ps -qf name=$(docker exec -it $(docker ps -qf name=mongo_mongodb3) mongo --eval 'rs.isMaster().primary' | grep  -oE '\mongo_mongodb[1-3]'))

# Проверяем что мастере переехал
docker exec -it $(docker ps -qf name=mongo_mongodb3) mongo --eval 'rs.isMaster().primary'

# Список баз данных
docker exec -it $(docker ps -qf name=mongo_mongodb3) mongo --quiet --eval 'db.getMongo().getDBNames()'
# или
docker exec -it $(docker ps -qf name=mongo_mongodb3) mongo --quiet --eval  "printjson(db.adminCommand('listDatabases'))"
