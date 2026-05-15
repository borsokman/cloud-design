#!/bin/bash
set -e

# Start RabbitMQ in the background
rabbitmq-server &
pid="$!"

sleep 10 # Wait for RabbitMQ to fully boot

# Run the commands from your old bash script
rabbitmqctl add_user "${RABBITMQ_USER}" "${RABBITMQ_PASSWORD}" 2>/dev/null || true
rabbitmqctl set_user_tags "${RABBITMQ_USER}" administrator
rabbitmqctl set_permissions -p / "${RABBITMQ_USER}" ".*" ".*" ".*"

# Bring to foreground
wait "$pid"