#!/bin/bash

# Export KUBECONFIG so kubectl commands work automatically
export KUBECONFIG=$PWD/k3s.yaml

case "$1" in
    create)
        echo "Creating VMs and Kubernetes cluster..."
        vagrant up
        
        echo "Waiting for cluster to become fully ready (15s)..."
        sleep 15
        
        echo "Deploying manifests..."
        kubectl apply -f manifests/secrets.yaml
        kubectl apply -f manifests/inventory-db.yaml
        kubectl apply -f manifests/billing-db.yaml
        kubectl apply -f manifests/rabbitmq-server.yaml
        kubectl apply -f manifests/inventory-app.yaml
        kubectl apply -f manifests/billing-app.yaml
        kubectl apply -f manifests/api-gateway-app.yaml
        
        echo "cluster created"
        ;;
    start)
        echo "Starting existing VMs..."
        vagrant up
        echo "cluster started"
        ;;
    stop)
        echo "Stopping VMs..."
        vagrant halt
        echo "cluster stopped"
        ;;
    *)
        echo "Usage: $0 {create|start|stop}"
        exit 1
        ;;
esac