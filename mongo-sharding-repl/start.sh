#!/bin/bash

# Скрипт для запуска и инициализации MongoDB sharded кластера с репликацией (2 реплики)

echo "🚀 Запуск MongoDB sharded кластера с репликацией (2 реплики)..."

# Запуск docker-compose
echo "🐳 Запуск контейнеров..."
sudo docker-compose -f compose.yaml up -d

# Ожидание запуска контейнеров
echo "⏳ Ожидание запуска контейнеров..."
sleep 20

# Проверка состояния контейнеров
echo "🔍 Проверка состояния контейнеров..."
sudo docker ps | grep mongos

# Инициализация config server replica set
echo "🔧 Инициализация config server replica set..."
sudo docker exec mongos_configsvr1 mongosh --port 27011 --eval "
rs.initiate({
  _id: 'config_server',
  configsvr: true,
  members: [
    {
      _id: 0,
      host: 'mongos_configsvr1:27011'
    },
    {
      _id: 1,
      host: 'mongos_configsvr2:27012'
    }
  ]
})
"

# Ожидание инициализации config server
echo "⏳ Ожидание инициализации config server..."
sleep 15

# Инициализация shard1 replica set
echo "🔧 Инициализация shard1 replica set..."
sudo docker exec mongos_shard1svr1 mongosh --port 27014 --eval "
rs.initiate({
  _id: 'shard1_replica',
  members: [
    {
      _id: 0,
      host: 'mongos_shard1svr1:27014'
    },
    {
      _id: 1,
      host: 'mongos_shard1svr2:27015'
    }
  ]
})
"

# Инициализация shard2 replica set
echo "🔧 Инициализация shard2 replica set..."
sudo docker exec mongos_shard2svr1 mongosh --port 27021 --eval "
rs.initiate({
  _id: 'shard2_replica',
  members: [
    {
      _id: 0,
      host: 'mongos_shard2svr1:27021'
    },
    {
      _id: 1,
      host: 'mongos_shard2svr2:27022'
    }
  ]
})
"

# Ожидание инициализации shards
echo "⏳ Ожидание инициализации shards..."
sleep 20

# Проверка статуса replica sets
echo "📊 Статус config server replica set:"
sudo docker exec mongos_configsvr1 mongosh --port 27011 --eval "rs.status()"

echo "📊 Статус shard1 replica set:"
sudo docker exec mongos_shard1svr1 mongosh --port 27014 --eval "rs.status()"

echo "📊 Статус shard2 replica set:"
sudo docker exec mongos_shard2svr1 mongosh --port 27021 --eval "rs.status()"

# Добавление shards в кластер через mongos
echo "🔗 Добавление shards в кластер..."
sudo docker exec mongos_router mongosh --port 27020 --eval "
sh.addShard('shard1_replica/mongos_shard1svr1:27014,mongos_shard1svr2:27015');
sh.addShard('shard2_replica/mongos_shard2svr1:27021,mongos_shard2svr2:27022');
"

echo "✅ Основная инициализация завершена!"

# Проверка статуса кластера
echo "📊 Статус sharded кластера:"
sudo docker exec mongos_router mongosh --port 27020 --eval "sh.status()"

# Ожидание стабилизации кластера
echo "⏳ Финальное ожидание стабилизации..."
sleep 15

# Запуск скрипта инициализации базы данных
echo "🌱 Запуск скрипта инициализации базы данных..."
sudo bash ./scripts/mongo-init.sh

echo "🎉 MongoDB sharded кластер с репликацией (2 реплики) полностью готов к работе!"
echo "🌐 Router доступен на порту 27020"