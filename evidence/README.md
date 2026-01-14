# Evidence – MuchTodo Container & Kubernetes Deployment

This folder contains **verifiable evidence** demonstrating the successful build, deployment, and exposure of the MuchTodo application using **Docker**, **Docker Compose**, and **Kubernetes (Kind)**.

Each screenshot corresponds directly to a step described in the main `README.md` and proves that the system is running correctly at each phase.

---

## Evidence Index

### 1. Docker Image Build

<img src="assets/screenshot.png" alt="Screenshot" width="75%">

**File:** `01-docker-build.png`  
**Description:**  
Shows successful execution of the Docker build process using the provided `Dockerfile`, producing the image:

- `muchtodo-backend:local`

**Command used:**

```bash
./scripts/docker-build.sh
```

---

### 2. Docker Compose Running Containers

**File:** `02-docker-compose-ps.png`
Description:
Shows both services running via Docker Compose, using the command:

```bash
docker compose ps
```

The screenshot confirms:

- muchtodo-backend → Up (healthy)

- muchtodo-mongodb → Up (healthy)

Both containers are part of the same Docker Compose stack

---

## 3 Application Responding via Docker Compose

**File:**  
`03-docker-compose-health.png`

**Description:**  
Shows the backend application responding successfully when accessed through Docker Compose using:

```bash
curl -i http://localhost:8080/health
```

The screenshot confirms:

- HTTP 200 OK response

- Backend API is running correctly

- MongoDB connection is successful

## 4 Kind Kubernetes Cluster Created

**File:**  
`04-kind-cluster-nodes.png`

**Description:**  
Shows the successful creation of a Kind Kubernetes cluster using:

```bash
kind create cluster --name muchtodo
kubectl get nodes
```

then to show the clusters after creation:

```bash
kind get clusters
kubectl get nodes
kubectl cluster-info
```

The screenshot confirms:

The screenshot confirms:

- Kind cluster muchtodo exists
- Control-plane node is in Ready state

## 5 Kubernetes Deployments Running

**File:**  
`05-kubernetes-pods-running.png`

**Description:**  
Shows all Kubernetes pods running successfully in the muchtodo namespace using:

```bash
kubectl get pods -n muchtodo
```

The screenshot confirms:

- MongoDB pod is running
- Backend pods are running

## No pods are in CrashLoopBackOff or Error state

## 6 Kubernetes Services and NodePort

**File:**  
`06-kubernetes-services.png`
**Description:**  
Shows the successful creation of Kubernetes services using:

```bash
kubectl get svc -n muchtodo
```

The screenshot confirms:

- backend-service is of type NodePort
- NodePort 30080 is exposed
- mongodb-service is of type ClusterIP

---

## 7 Applicatio Accessible via NodePort

**File:**  
`07-nodeport-access.png`

**Description:**  
Shows the backend application being accessed from the host machine through the Kubernetes NodePort using:

```bash
curl -i http://localhost:30080/health
```

The screenshot confirms:

- HTTP 200OK response
- Application is accessible via Kubernetes NodePort

---

## 8 Kubernetes Ingress Resource

**File:**  
`08-kubernetes-ingress.png`
**Description:**  
Shows the Ingress resource created successfully using:

```bash
kubectl get ingress -n muchtodo
```

The screenshot confirms:

- Ingress resource exists
- Host muchtodo.local configured correctly

---

## 9 Application Accessible via Ingress

**File:**  
`09-ingress-access.png`

**Description:**  
Shows the backend application being accessed through Kubernetes Ingress after updating /etc/hosts using:

```bash
curl -i http://muchtodo.local/health
```

The screenshot confirms:

- HTTP 200OK response
- Application is accessible via Kubernetes Ingress
