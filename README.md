### Разворачиваем mongodb кластер в docker swarm

`docker stack deploy -c mongo-deploy.yml mongo`

для запуска сценария развертывания и проверки работы кластера, выполните:
`./command.sh` - он выполнит выше указанную команду и еще кучу других :)

Для наглядности работы развернут koalb сервер

http://localhost:8080
или
http://ip:8080

Для резервного копирования и восстановления баз данных, развернут контейнер со скриптами резервного копирования (выполняется по крону или произвольно) и восстановления

имя контейнера: mongo_backup

работа с контейнером:

Backup:

`docker exec -it $(docker ps -qf name=mongo_mongodb_backup) ./backup.sh`

Востановление:

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
