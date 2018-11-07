
#Запускаем Swarm cluster
echo "Запускаем Swarm cluster"
if [ "$(docker info | grep Swarm | sed 's/Swarm: //g')" == "inactive" ]; then
        echo "swarm не активен"
        echo "Запускаем инициализацию"
        docker swarm init
    else
        echo "swarm активен"
        echo true;
    fi

# Разворачиваем проект в класторе swarm
echo "Deploy mongo!"
docker stack deploy -c mongo-deploy.yml mongo

echo "Ждем 20 сек"
sleep 20

# Запускаем репликацию
echo "Запускаем репликацию"
docker exec -it $(docker ps -qf name=mongo_mongodb1) mongo --quiet --eval 'rs.initiate({ _id: "example", members: [{ _id: 1, host: "mongo_mongodb1:27017" }, { _id: 2, host: "mongo_mongodb2:27017" }, { _id: 3, host: "mongo_mongodb3:27017" }], settings: { getLastErrorDefaults: { w: "majority", wtimeout: 30000 }}})'

echo "Ждем 10 сек"
sleep 10

# Проверка
echo "Проверка"
docker exec -it $(docker ps -qf name=mongo_mongodb1)  mongo --quiet --eval 'rs.status()'

# Запускуаем koalab service
#docker service create --env 'MONGO_URL=mongodb://mongo_mongodb1:27017,mongo_mongodb2:27017,mongo_mongodb3:27017/koalab?replicaSet=example' --name koalab --network mongo_mongonet --replicas 2 --publish 8080:8080 kalahari/koalab
# Добавлен в кластер...

# Check master in db cluster
echo "Смотрим кто мастер"
docker exec -it $(docker ps -qf name=mongo_mongodb3) mongo --quiet --eval 'rs.isMaster().primary'


# docker exec -it $(docker ps -qf name=mongo_mongodb3) mongo --eval 'rs.isMaster().primary' | grep  -oE '\mongo_mongodb[1-3]'
# Stop master container
# docker stop $(docker ps -qf name=mongo_mongodb1)
# Определяем мастера и тушим контейнер с ним
echo "Определяем мастера и тушим контейнер с ним (для проверки работы кластера)"
docker stop $(docker ps -qf name=$(docker exec -it $(docker ps -qf name=mongo_mongodb3) mongo --eval 'rs.isMaster().primary' | grep  -oE '\mongo_mongodb[1-3]'))

echo "Ждем 11 сек"
sleep 11

# Проверяем что мастер переехал
echo "Проверяем что мастер переехал"
docker exec -it $(docker ps -qf name=mongo_mongodb3) mongo --quiet --eval 'rs.isMaster().primary'

# Список баз данных
echo "Ну и на последок - список баз данных"
docker exec -it $(docker ps -qf name=$(docker exec -it $(docker ps -qf name=mongo_mongodb3) mongo --quiet --eval 'rs.isMaster().primary' | grep  -oE '\mongo_mongodb[1-3]')) mongo --quiet --eval 'db.getMongo().getDBNames()'

# Перевыборы мастера - Ручками
