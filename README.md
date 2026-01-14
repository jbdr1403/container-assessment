# MuchTodo — Containerization & Kubernetes (Kind) Deployment Guide (A–Z)

This repository contains a complete **Docker** + **Docker Compose** local setup and a **Kubernetes (Kind)** deployment for the MuchTodo **Golang API** with **MongoDB**.

This README is written as a **step-by-step beginner guide** you can follow from start to finish.

---

## 1) What You Are Deploying

### Components

- **Backend API**: Golang REST API
  - Runs on port **8080**
  - Health endpoint: **GET `/health`**
- **Database**: **MongoDB**
  - Uses persistent storage (Docker volume / Kubernetes PVC)

### What “Done” Looks Like

- Docker Compose:
  - `curl http://localhost:8080/health` returns **200**
- Kubernetes (Kind):
  - `curl http://localhost:30080/health` returns **200**
  - Optional: `curl http://muchtodo.local/health` returns **200** via Ingress

---

## 2) Project Structure

```text
container-assessment/
├── much-to-do/                      # application source (backend)
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── kind-config.yaml
├── kubernetes/
│   ├── namespace.yaml
│   ├── mongodb/
│   │   ├── mongodb-secret.yaml
│   │   ├── mongodb-configmap.yaml
│   │   ├── mongodb-pvc.yaml
│   │   ├── mongodb-deployment.yaml
│   │   └── mongodb-service.yaml
│   ├── backend/
│   │   ├── backend-secret.yaml
│   │   ├── backend-configmap.yaml
│   │   ├── backend-envfile-configmap.yaml
│   │   ├── backend-deployment.yaml
│   │   └── backend-service.yaml
│   └── ingress.yaml
├── scripts/
│   ├── docker-build.sh
│   ├── docker-run.sh
│   ├── k8s-deploy.sh
│   └── k8s-cleanup.sh
└── evidence/                        # screenshots for submission

```

---

## 3) Prerequisites (Install + Verify)

### Required Tools

- Docker Desktop (https://www.docker.com/products/docker-desktop)
- Docker Compose (https://docs.docker.com/compose/install/)
- kubectl (https://kubernetes.io/docs/tasks/tools/)
- kind (https://kind.sigs.k8s.io/docs/user/quick-start/)
- openssl (https://www.openssl.org/source/)

### Verify

- `docker --version`
- `docker-compose --version`
- `kubectl version --client`
- `kind version`
- `openssl version`

Expected:

- Docker works (no “command not found”)

- kubectl shows a client version

- kind returns a version

---

## 4) Go to the Correct Folder (Very Important)

All commands in this guide are run from the project root directory:

```bash
cd ~/Desktop/cloud-engineering/container-assessment
pwd
```

Your `pwd` should end with:

```bash
.../container-assessment
```

# PHASE 1: Docker (Local Development)

## 5) What Docker Does Here (Simple Explanation)

- Docker builds a container image for the backend API
- Docker compose runs:
  - The backend API container
  - MongoDB container
- Backend connects to MongoDB using `MONGO_URI`.

## 6) Build the Backend Docker Image

```bash
./scripts/docker-build.sh
```

What you should see:

- Docker builds successfully
- Image exists locally

Check

```bash
docker images | grep muchtodo
```

## 7) Run with Docker Compose

Start Containers

```bash
./scripts/docker-run.sh
```

This script:

- generates `mongodb.key` if missing
- starts container with docker compose up -d
- runs a basic health check

Confirm containers are running

```bash
docker ps
```

You should see:

- `muchtodo-mongodb`
- `muchtodo-backend`

## 8) Test the Backend (Docker)

Health endpoint

```bash
curl -i http://localhost:8080/health
```

Expected:

- HTTP status 200
- JSON like:

```bash
{"cache":"disabled","database":"ok"}
```

---

# PHASE 2: Kubernetes (Production)

## 9) What Kubernetes Does Here (Simple Explanation)

In Kubernetes, we create “objects” using YAML files:

**MongoDB needs**:

- Secret (credentials)
- ConfigMap (non-secret config)
- PVC (persistent volume claim)
- Deployment (runs the MongoDB pod)
- Service (stable network name so backend can connect)

**Backend needs**:

- Secret (JWT secret)
- ConfigMaps (MONGO URI, DB_NAME, etc.)
- Deployment (2 replicas)
- Service (NodePort so you can access from your laptop)

Optional:

- Ingress (pretty URL like muchtodo.local)

---

## 10) Create Kind Cluster (with port mapping)

Crate the Cluster

```bash
kind create cluster --name muchtodo --config kind-config.yaml
```

Wait Until node is ready

```bash
kubectl wait --for=condition=Ready node --all --timeout=120s
kubectl get nodes
```

You should see one node in Ready state.

## 11) Load Docker Image into Kind

Kind clusters can’t automatically see your local Docker images, so we load it in:

```bash
kind load docker-image muchtodo-backend:local --name muchtodo
```

This makes the `muchtodo-backend:local` image available inside the Kind cluster.

## 12) Deploy Kubernetes Manifests (in the right order)

Create namespace

```bash
kubectl apply -f kubernetes/namespace.yaml
kubectl get ns | grep muchtodo
```

Deploy MongoDB (Kubernetes)
Secret

```bash
kubectl apply -f kubernetes/mongodb/mongodb-secret.yaml
kubectl get secrets -n muchtodo
```

ConfigMap

```bash
kubectl apply -f kubernetes/mongodb/mongodb-configmap.yaml
kubectl get configmaps -n muchtodo
```

PVC (storage)

```bash
kubectl apply -f kubernetes/mongodb/mongodb-pvc.yaml
kubectl get pvc -n muchtodo
```

Note: It may show Pending at first. This is normal if the StorageClass is `WaitForFirstConsumer`.

Deployment

```bash
kubectl apply -f kubernetes/mongodb/mongodb-deployment.yaml
kubectl get pods -n muchtodo
```

Service

```bash
kubectl apply -f kubernetes/mongodb/mongodb-service.yaml
kubectl get svc -n muchtodo
```

## 13) Deploy Backend (Kubernetes)

secret

```bash
kubectl apply -f kubernetes/backend/backend-secret.yaml
kubectl get secrets -n muchtodo | grep backend
```

ConfigMaps

```bash
kubectl apply -f kubernetes/backend/backend-configmap.yaml
kubectl apply -f kubernetes/backend/backend-envfile-configmap.yaml
kubectl get configmaps -n muchtodo | grep backend

```

Deployment

```bash
kubectl apply -f kubernetes/backend/backend-deployment.yaml
kubectl get pods -n muchtodo -l app=backend
```

Service (NodePort)

```bash
kubectl apply -f kubernetes/backend/backend-service.yaml
kubectl get svc -n muchtodo

```

Wait for everything to be ready

```bash
kubectl wait -n muchtodo --for=condition=Ready pod -l app=mongodb --timeout=180s
kubectl wait -n muchtodo --for=condition=Ready pod -l app=backend --timeout=180s
kubectl get pods -n muchtodo
```

## 14) Test Backend with NodePort

Because Kind port mappings expose NodePort to your laptop, test like this:

```bash
curl -i http://localhost:30080/health
```

Expected:

- HTTP status 200
- JSON:

```bash
{"cache":"disabled","database":"ok"}
```

## 15) Ingress Setup

Ingress is a Kubernetes resource that allows you to expose your services to the internet. In this case, we will use an Ingress resource to expose the frontend and backend services to the internet.

Ingress Setup (Install ingress-nginx (for Kind)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
```

Apply ingress resource

```bash
kubectl apply -f kubernetes/ingress.yaml
kubectl get ingress -n muchtodo
```

Add local hostname

```bash
echo "127.0.0.1 muchtodo.local" | sudo tee -a /etc/hosts
```

Test ingress

```bash
curl -i http://muchtodo.local/health
```

## 16) Troubleshooting (Kubernetes)

Backend CrashLoopBackOff
Check logs:

```bash
kubectl logs -n muchtodo -l app=backend --tail 100
```

If it says Mongo URI scheme invalid, ensure `MONGO_URI` begins with:

```bash
mongodb://
```

Describe pod to see env + events:

```bash
kubectl describe pod -n muchtodo -l app=backend
```

Restart backend deployment after changes:

```bash
kubectl rollout restart deployment/backend -n muchtodo
kubectl get pods -n muchtodo -l app=backend
```

## 17) Cleanup

Delete Kind cluster

```bash
./scripts/k8s-cleanup.sh
```

## This deletes the Kind cluster named `muchtodo`.

## 18) Evidence Checklist

(Screenshots to save in evidence/)

---
