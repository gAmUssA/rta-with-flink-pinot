#!/bin/bash
# wait-for-kafka.sh

set -e

host="kafka"
port="29092"

until nc -z $host $port; do
  echo "Waiting for Kafka to be ready... "
  sleep 1
done

echo "Kafka is ready!"
exec "$@"