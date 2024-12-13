#!/bin/bash

# Wait for Pinot Controller to be ready
until curl -s http://localhost:9000/health > /dev/null; do
    echo -e "Waiting for Pinot Controller...\n"
    sleep 5
done

echo -e "\nAdding schemas..."
curl -X POST -H "Content-Type: application/json" -d @config/schemas/product_analytics.json http://localhost:9000/schemas
curl -X POST -H "Content-Type: application/json" -d @config/schemas/active_users.json http://localhost:9000/schemas
curl -X POST -H "Content-Type: application/json" -d @config/schemas/user_sessions.json http://localhost:9000/schemas

echo -e "\nAdding tables..."
# Add tables
curl -X POST -H "Content-Type: application/json" -d @config/tables/product_analytics.json http://localhost:9000/tables
curl -X POST -H "Content-Type: application/json" -d @config/tables/active_users.json http://localhost:9000/tables
curl -X POST -H "Content-Type: application/json" -d @config/tables/user_sessions.json http://localhost:9000/tables

echo -e "\nInitialization complete!\n"
