#!/bin/bash

# Скрипт для запуска и инициализации MongoDB sharded кластера

echo "🚀 Запуск MongoDB sharded кластера..."

# Запуск sudo docker-compose
echo "🐳 Запуск контейнеров..."
sudo docker-compose -f compose.yaml up -d

# Ожидание запуска контейнеров
echo "⏳ Ожидание запуска контейнеров..."
sleep 10

# Проверка состояния контейнеров
echo "🔍 Проверка состояния контейнеров..."
sudo docker ps | grep mongos

# Инициализация config server replica set
echo "🔧 Инициализация config server replica set..."
sudo docker exec mongos_configSrv mongosh --port 27017 --eval "
rs.initiate({
  _id: 'config_server',
  configsvr: true,
  members: [
    {
      _id: 0,
      host: 'mongos_configSrv:27017'
    }
  ]
})
"

# Ожидание инициализации config server
echo "⏳ Ожидание инициализации config server..."
sleep 5

# Инициализация shard1 replica set
echo "🔧 Инициализация shard1 replica set..."
sudo docker exec mongos_shard1 mongosh --port 27018 --eval "
rs.initiate({
  _id: 'mongos_shard1',
  members: [
    {
      _id: 0,
      host: 'mongos_shard1:27018'
    }
  ]
})
"

# Инициализация shard2 replica set
echo "🔧 Инициализация shard2 replica set..."
sudo docker exec mongos_shard2 mongosh --port 27019 --eval "
rs.initiate({
  _id: 'mongos_shard2',
  members: [
    {
      _id: 0,
      host: 'mongos_shard2:27019'
    }
  ]
})
"

# Ожидание инициализации shards
echo "⏳ Ожидание инициализации shards..."
sleep 10

# Добавление shards в кластер через mongos
echo "🔗 Добавление shards в кластер..."
sleep 5

sudo docker exec mongos_router mongosh --port 27020 --eval "
sh.addShard('mongos_shard1/mongos_shard1:27018');
sh.addShard('mongos_shard2/mongos_shard2:27019');
"

echo "✅ Основная инициализация завершена!"

# Проверка статуса кластера
echo "📊 Статус кластера:"
sudo docker exec mongos_router mongosh --port 27020 --eval "sh.status()"

# Ожидание стабилизации кластера
echo "⏳ Финальное ожидание стабилизации..."
sleep 5

# Запуск скрипта инициализации базы данных
echo "🌱 Запуск скрипта инициализации базы данных..."
sudo bash ./scripts/mongo-init.sh

echo "🎉 MongoDB sharded кластер полностью готов к работе!"
echo "🌐 Router доступен на порту 27020"