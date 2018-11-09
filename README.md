### Схема кластера

![https://docs.mongodb.com/manual/_images/replica-set-read-write-operations-primary.bakedsvg.svg](https://docs.mongodb.com/manual/_images/replica-set-read-write-operations-primary.bakedsvg.svg)

![https://docs.mongodb.com/manual/_images/replica-set-primary-with-two-secondaries.bakedsvg.svg](https://docs.mongodb.com/manual/_images/replica-set-primary-with-two-secondaries.bakedsvg.svg)

![https://docs.mongodb.com/manual/_images/replica-set-trigger-election.bakedsvg.svg](https://docs.mongodb.com/manual/_images/replica-set-trigger-election.bakedsvg.svg)

_Сдохший мастер возврошается в кластер слейвом._


### Разворачиваем mongodb кластер в docker swarm

![https://sreeninet.files.wordpress.com/2015/05/docker5.png](https://sreeninet.files.wordpress.com/2015/05/docker5.png)

`docker stack deploy -c mongo-deploy.yml mongo`

для запуска сценария развертывания и проверки работы кластера, выполните:
`./command.sh` - он выполнит выше указанную команду и еще кучу других :)

Для наглядности работы развернут [koalab](https://hub.docker.com/r/kalahari/koalab/) сервер

![https://raw.githubusercontent.com/AF83/koalab/master/public/screenshots/board.png](https://raw.githubusercontent.com/AF83/koalab/master/public/screenshots/board.png)

http://localhost:8080
или
http://ip:8080

Для резервного копирования и восстановления баз данных, развернут контейнер со скриптами резервного копирования (выполняется по крону или произвольно) и восстановления

Имя контейнера: **mongo_backup**

работа с контейнером:

#####Backup:

`docker exec -it $(docker ps -qf name=mongo_mongodb_backup) ./backup.sh`

#####Restore:

`docker exec -it $(docker ps -qf name=mongo_mongodb_backup) ./restore.sh koalab /bacup/koalab/date`



### Работа с кластером mongodb

##### Сбрасывание PRIMARY.
Смена первичного узла и переназначение приоритетов

`rs.stepDown(60,40)`

60 секунд — время, в течение которого сервер, с которого запущено выполнение команды, не может стать Primary; 40 секунд — время перевыборов нового Primary.

`db.adminCommand({replSetStepDown: 30, force: 1})`

30 секунд — время отключения Primary и перевыборы. Выполнение команды допустимо с любого из серверов mongoDB.

`rs.stepDown(60)`

Узел, с которого запущена команда, в течение 60 секунд не сможет стать Primary.

/var/lib/mongodb/ — Тут лежат файлы баз.

Список баз данных

`mongo --quiet --eval  "printjson(db.adminCommand('listDatabases'))"`

### Создание дампа
создание бэкапа всех баз в папку Backup:

`mongodump --out /Backup`

создание бэкапа отдельной базы:

`mongodump  --db <Имя БД> --out /Backup`

создание бэкапа отдельной таблицы:

`mongodump  --db <Имя БД> --collection <Имя коллекции>--out /Backup`

Запуск от имени root, создание бэкапа указанной базы в указанный каталог + текущая дата:

`sudo mongodump --db newdb --out /var/backups/mongobackups/'date +"%m-%d-%y"'`

### Восстановление из дампа:
Восстанавление базы в каталог по умолчанию. Если файл в с таким именем есть, то он перезаписывается:

`mongorestore <Имя БД>`

Восстановление всех баз из указанного каталога:

`mongorestore ./Backup`

Восстановление отдельной таблицы(коллекции):

`mongorestore --collection <коллекция> --db <Имя БД> dump/`


### Перевыборы мастера

#### Прибиваем гвоздями роль мастера

`cfg = rs.conf()`

Выбирится эта нода приоритет при голосовании, так как стоит наибольший приоритет
На мастере нельзя понизить приоритет в конфиге - пока он мастер.
```
cfg.members[0].votes = 1;
cfg.members[0].priority = 2;
cfg.members[1].votes = 1;
cfg.members[1].priority = 1;
cfg.members[2].votes = 1;
cfg.members[2].priority = 1;
cfg.members[3].votes = 1
cfg.members[3].priority = 1;
rs.reconfig(cfg);
```
#### Выводим мастера из кластера

Заходим на мастер и выполняем :

`rs.stepDown();`

Проверяем:

`rs.isMaster().primary;`

В случае если SECONDARY сервера не хотят синхрониться

Выполним команду:

`rs.slaveOk()`


Получаем список баз от мастера в docker'е

`docker exec -it $(docker ps -qf name=$(docker exec -it $(docker ps -qf name=mongo_mongodb3) mongo --quiet --eval 'rs.isMaster().primary' | grep  -oE '\mongo_mongodb[1-3]')) mongo --quiet --eval 'db.getMongo().getDBNames()'`


####Примечание:

Для нормальной работы Swarm на разных машинах, необходимо прописать правила Firewall

CentOS 7

    firewall-cmd --add-port=2376/tcp --permanent
    firewall-cmd --add-port=2377/tcp --permanent
    firewall-cmd --add-port=7946/tcp --permanent
    firewall-cmd --add-port=7946/udp --permanent
    firewall-cmd --add-port=4789/udp --permanent

Добавление управляющей ноды

$ docker swarm join-token manager
To add a manager to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-1yptom678kg6hryfufjyv1ky7xc4tx73m8uu2vmzm1rb82fsas-c12oncaqr8heox5ed2jj50kjf \
    172.28.128.3:2377

Добавление рабочей ноды

$ docker swarm join-token worker
To add a worker to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-1yptom678kg6hryfufjyv1ky7xc4tx73m8uu2vmzm1rb82fsas-511vapm98iiz516oyf8j00alv \
    172.28.128.3:2377

Копирование файлов:

The cp command can be used to copy files. One specific file can be copied like:

`docker cp foo.txt mycontainer:/foo.txt`
`docker cp mycontainer:/foo.txt foo.txt`

For emphasis, mycontainer is a container ID, not an image ID.

Multiple files contained by the folder src can be copied into the target folder using:

`docker cp src/. mycontainer:/target`
`docker cp mycontainer:/src/. target`


Get container name or short container id:
`docker ps`

Get full container id:
`docker inspect -f   '{{.Id}}'  SHORT_CONTAINER_ID-or-CONTAINER_NAME`

Copy file:
`sudo cp path-file-host /var/lib/docker/aufs/mnt/FULL_CONTAINER_ID/PATH-NEW-FILE`



Особенностью MongoDb является то, что это документо-ориентированная база данных, и не содержит информацию о структуре, так что тут мы закончили.