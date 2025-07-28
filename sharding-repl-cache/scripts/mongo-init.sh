#!/bin/bash

# Скрипт инициализации базы данных MongoDB

echo "🌱 Начало инициализации базы данных..."

# Подключение к mongos через правильный порт
echo "🔌 Подключение к MongoDB router и наполнение данными..."
sudo docker-compose exec -T mongos_router mongosh --port 27020 <<EOF
use somedb;
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF

echo "🎉 Инициализация базы данных завершена!"