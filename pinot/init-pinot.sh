#!/bin/bash

echo -e "Waiting for Pinot Controller...\n"
while ! curl -s http://pinot-controller:9000/health > /dev/null; do
    echo "Waiting for Pinot Controller..."
    sleep 5
done

echo -e "\nAdding schemas..."
curl -X POST -H "Content-Type: application/json" -d @/config/schemas/product_analytics.json http://pinot-controller:9000/schemas
curl -X POST -H "Content-Type: application/json" -d @/config/schemas/active_users.json http://pinot-controller:9000/schemas
curl -X POST -H "Content-Type: application/json" -d @/config/schemas/user_sessions.json http://pinot-controller:9000/schemas

echo -e "\nAdding tables..."
curl -X POST -H "Content-Type: application/json" -d @/config/tables/product_analytics.json http://pinot-controller:9000/tables
curl -X POST -H "Content-Type: application/json" -d @/config/tables/active_users.json http://pinot-controller:9000/tables
curl -X POST -H "Content-Type: application/json" -d @/config/tables/user_sessions.json http://pinot-controller:9000/tables

echo -e "\nInitialization complete!\n"
