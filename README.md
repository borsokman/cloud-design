# orchestrator

This project provisions a microservices architecture using Kubernetes (K3s) and Vagrant. It migrates a multi-tier application into isolated Pods running PostgreSQL, RabbitMQ, and Python/Pika services.

## Architecture Overview

It implements a scalable microservices architecture on a 2-node Kubernetes (K3s) cluster provisioned via Vagrant. The system is designed for high availability, asynchronous processing, and persistent data storage.

### Infrastructure (K3s Cluster)

- **Master Node:** Runs the Kubernetes control plane and API server (`192.168.56.10`). Traefik ingress is disabled to rely on native Service LoadBalancers.
- **Agent Node:** Worker node (`192.168.56.11`) where workloads are scheduled.
- **Networking:** Flannel CNI is explicitly bound to the private host-only network to ensure reliable cross-node pod communication.

### Application Components

- **API Gateway (`api-gateway-app`):**
  - The single entry point exposed to the host machine via a `LoadBalancer` service on port 3000.
  - Deployed as a `Deployment` with a Horizontal Pod Autoscaler (HPA) configured to scale up to 3 replicas when CPU exceeds 60%.
  - Routes synchronous requests to the Inventory Service and publishes asynchronous events to RabbitMQ.
- **Inventory Service (`inventory-app`):**
  - Handles synchronous REST API calls (CRUD operations for movies).
  - Deployed as a `Deployment` with HPA (scales up to 3 replicas at 60% CPU).
- **Billing Service (`billing-app`):**
  - An asynchronous background worker that consumes order messages from RabbitMQ.
  - Deployed as a `StatefulSet` to guarantee strict, ordered processing and stable network identity.

### Data & Messaging Layer

- **PostgreSQL Databases (`inventory-db` & `billing-db`):**
  - Isolated database instances for each service (Database-per-Service pattern).
  - Deployed as `StatefulSets` with `PersistentVolumeClaims` (PVCs).
  - Uses the K3s default `local-path` provisioner to ensure data survives pod restarts.
- **RabbitMQ (`rabbitmq-server`):**
  - Message broker deployed to decouple the API Gateway from the Billing Service.
  - Facilitates reliable, asynchronous inter-service communication.

## Prerequisites

- Vagrant
- VirtualBox
- kubectl CLI tool

## Infrastructure Setup & Management

### Build the Master and Agent VMs and Kubernetes cluster

chmod +x orchestrator.sh
./orchestrator.sh start

### Before the kubectl test commands everytime on a new terminal

export KUBECONFIG=$PWD/k3s.yaml

### Test the cluster

kubectl get nodes

### Verify the HPA (Autoscaling 1%/60%)

kubectl get hpa

## API Testing with Postman

A Postman Collection is included in the repository to automate the audit tests:
Open Postman and click Import.
Select the orchestrator_API_tests.json file.
In the imported collection, go to the Variables tab.
Ensure base_url is set to http://192.168.56.10:3000 (or your VM's IP if testing remotely).
Run the requests to verify Inventory CRUD operations and the asynchronous Billing Queue.

## Autoscalling test

Step 1: Open a terminal and watch the autoscaler live: kubectl get hpa -w

Step 2: Open a second terminal and watch the pods: kubectl get pods -w

Step 3: Open a third terminal and generate massive load Run this infinite loop to spam the API with hundreds of requests per second: while true; do curl -s http://192.168.56.10:3000/api/movies > /dev/null; done

Push docker images after AWS infrastructure being established

aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin 327425719370.dkr.ecr.eu-north-1.amazonaws.com

docker pull borsok/api-gateway-app:v1
docker pull borsok/inventory-app:v1
docker pull borsok/billing-app:v1
docker pull borsok/rabbitmq-server:v1
docker pull borsok/inventory-db:v1
docker pull borsok/billing-db:v1

docker tag borsok/api-gateway-app:v1 327425719370.dkr.ecr.eu-north-1.amazonaws.com/api-gateway-app:v1
docker tag borsok/inventory-app:v1 327425719370.dkr.ecr.eu-north-1.amazonaws.com/inventory-app:v1
docker tag borsok/billing-app:v1 327425719370.dkr.ecr.eu-north-1.amazonaws.com/billing-app:v1
docker tag borsok/rabbitmq-server:v1 327425719370.dkr.ecr.eu-north-1.amazonaws.com/rabbitmq-server:v1
docker tag borsok/inventory-db:v1 327425719370.dkr.ecr.eu-north-1.amazonaws.com/inventory-db:v1
docker tag borsok/billing-db:v1 327425719370.dkr.ecr.eu-north-1.amazonaws.com/billing-db:v1

docker push 327425719370.dkr.ecr.eu-north-1.amazonaws.com/api-gateway-app:v1
docker push 327425719370.dkr.ecr.eu-north-1.amazonaws.com/inventory-app:v1
docker push 327425719370.dkr.ecr.eu-north-1.amazonaws.com/billing-app:v1
docker push 327425719370.dkr.ecr.eu-north-1.amazonaws.com/rabbitmq-server:v1
docker push 327425719370.dkr.ecr.eu-north-1.amazonaws.com/inventory-db:v1
docker push 327425719370.dkr.ecr.eu-north-1.amazonaws.com/billing-db:v1

Step 1: Send a POST request via the Browser Console
Open your browser to your working URL: https://microservices-alb-1244665812.eu-north-1.elb.amazonaws.com/api/movies (Make sure you see []).
Press F12 to open Developer Tools and click on the Console tab.
Copy and paste this exact JavaScript code into the console and hit Enter:

fetch('/api/movies', {
method: 'POST',
headers: { 'Content-Type': 'application/json' },
body: JSON.stringify({
title: "AWS Cloud Audit",
description: "Testing my microservices"
})
}).then(res => res.json()).then(console.log);
Refresh your browser page. You will no longer see []. You will see the movie you just added! This proves the inventory-app successfully wrote to the PostgreSQL database.

Step 2: Test the Billing App (RabbitMQ)
Do the exact same thing, but point it to your billing route (adjust the URL and JSON payload to match whatever your billing-app expects):

fetch('/api/billing', {
method: 'POST',
headers: { 'Content-Type': 'application/json' },
body: JSON.stringify({
user_id: "auditor_123",
amount: 100.00
})
}).then(res => res.json()).then(console.log);
Step 3: Show the Auditor the Proof in AWS
Instead of showing a terminal, show them CloudWatch:

Go to the AWS Console -> CloudWatch -> Log groups.
Open /ecs/microservices/rabbitmq-server to show that the broker is running and accepting connections.
Open /ecs/microservices/billing-app to show the logs where your Python code successfully processed the billing request from the RabbitMQ queue.

Verify Deployment via AWS CLI
The auditor explicitly asks you to show the use of the AWS CLI to verify the deployment (since you aren't using Kubernetes/kubectl). Run these commands in your terminal to prove to the auditor that everything is running:

Show the cluster exists:

bash
aws ecs list-clusters --region eu-north-1
Show all 6 services are running:

bash
aws ecs list-services --cluster microservices-cluster --region eu-north-1
Show that the tasks (containers) are active:

bash
aws ecs list-tasks --cluster microservices-cluster --region eu-north-1

Q: Are the microservices communicating securely (auth/encryption)?
You need to hit 3 points here to impress the auditor:

Authentication: "We offloaded authentication to the edge. Go to the Load Balancer, look at the Listeners, and you will see AWS Cognito intercepts all traffic before it even touches our containers."
Encryption: "External traffic is encrypted via HTTPS using an AWS ACM certificate attached to the Load Balancer."
Network Security: "Inside the cloud, communication is highly secure. First, all microservices are in Private Subnets with no public IP addresses. Second, we use strict Security Groups (Firewalls) so the databases only accept traffic from the application layer on port 5432. Finally, database passwords are not hardcoded; they are encrypted using AWS SSM Parameter Store and injected securely into the containers at runtime."

AutoScaling Trigger Test:

while true; do curl -s -k "https://microservices-alb-XXXXXXXX.eu-north-1.elb.amazonaws.com/api/movies" -H "cookie: AWSELBAuthSessionCookie-0=YOUR_COOKIE_HERE" > /dev/null; done

Policy
aws application-autoscaling describe-scaling-policies --service-namespace ecs --region eu-north-1

Billing resilience test:

Stop billing-app
aws ecs update-service --cluster microservices-cluster --service billing-app-service --desired-count 0 --region eu-north-1

Send billing request through the browser console:
fetch('/api/billing', {
method: 'POST',
headers: { 'Content-Type': 'application/json' },
body: JSON.stringify({
user_id: "auditor_test_123",
number_of_items: 7,
total_amount: 500.00
})
}).then(res => res.json()).then(console.log);

Restart the Billing Service:
aws ecs update-service --cluster microservices-cluster --service billing-app-service --desired-count 1 --region eu-north-1

## Project Tree

```
cloud-design
├─ Manifests
│  ├─ api-gateway-app.yaml
│  ├─ billing-app.yaml
│  ├─ billing-db.yaml
│  ├─ inventory-app.yaml
│  ├─ inventory-db.yaml
│  ├─ rabbitmq-server.yaml
│  └─ secrets.yaml
├─ README.md
├─ Vagrantfile
├─ architecture.png
├─ docker-compose.yml
├─ orchestrator.sh
├─ srcs
│  ├─ api-gateway-app
│  │  ├─ Dockerfile
│  │  ├─ app
│  │  │  ├─ __init__.py
│  │  │  ├─ config.py
│  │  │  └─ routes.py
│  │  ├─ requirements.txt
│  │  └─ server.py
│  ├─ billing-app
│  │  ├─ Dockerfile
│  │  ├─ app
│  │  │  ├─ __init__.py
│  │  │  ├─ consumer.py
│  │  │  └─ models.py
│  │  ├─ requirements.txt
│  │  └─ server.py
│  ├─ billing-db
│  │  ├─ Dockerfile
│  │  └─ entrypoint.sh
│  ├─ inventory-app
│  │  ├─ Dockerfile
│  │  ├─ app
│  │  │  ├─ __init__.py
│  │  │  ├─ models.py
│  │  │  └─ routes.py
│  │  ├─ requirements.txt
│  │  └─ server.py
│  ├─ inventory-db
│  │  ├─ Dockerfile
│  │  └─ entrypoint.sh
│  └─ rabbitmq-server
│     ├─ Dockerfile
│     └─ entrypoint.sh
└─ terraform
   ├─ acm.tf
   ├─ alb.tf
   ├─ autoscaling.tf
   ├─ cognito.tf
   ├─ discovery.tf
   ├─ ecr.tf
   ├─ ecs.tf
   ├─ ecs_services.tf
   ├─ ecs_tasks.tf
   ├─ logs.tf
   ├─ network.tf
   ├─ output.tf
   ├─ provider.tf
   ├─ secrets.tf
   ├─ security.tf
   └─ storage.tf

```
