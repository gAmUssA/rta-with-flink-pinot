#!/bin/bash

# Wait for Pinot Controller to be ready
until curl -s http://localhost:9000/health > /dev/null; do
    echo "Waiting for Pinot Controller..."
    sleep 5
done

# Add schemas
curl -X POST -H "Content-Type: application/json" -d @/config/tables/product_analytics_schema.json http://pinot-controller:9000/schemas
curl -X POST -H "Content-Type: application/json" -d @/config/tables/active_users_schema.json http://pinot-controller:9000/schemas
curl -X POST -H "Content-Type: application/json" -d @/config/tables/user_sessions_schema.json http://pinot-controller:9000/schemas

# Add tables
curl -X POST -H "Content-Type: application/json" -d @/config/tables/product_analytics.json http://pinot-controller:9000/tables
curl -X POST -H "Content-Type: application/json" -d @/config/tables/active_users.json http://pinot-controller:9000/tables
curl -X POST -H "Content-Type: application/json" -d @/config/tables/user_sessions.json http://pinot-controller:9000/tables
