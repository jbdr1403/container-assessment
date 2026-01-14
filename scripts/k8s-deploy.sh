#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="muchtodo"
IMAGE_NAME="muchtodo-backend:local"

echo "Creating kind cluster (${CLUSTER_NAME}) with port mappings..."
kind create cluster --name "${CLUSTER_NAME}" --config kind-config.yaml

echo "Waiting for nodes..."
kubectl wait --for=condition=Ready node --all --timeout=120s

echo "Loading image into kind..."
kind load docker-image "${IMAGE_NAME}" --name "${CLUSTER_NAME}"

echo "Deploying manifests..."
kubectl apply -f kubernetes/namespace.yaml

kubectl apply -f kubernetes/mongodb/mongodb-secret.yaml
kubectl apply -f kubernetes/mongodb/mongodb-configmap.yaml
kubectl apply -f kubernetes/mongodb/mongodb-pvc.yaml
kubectl apply -f kubernetes/mongodb/mongodb-deployment.yaml
kubectl apply -f kubernetes/mongodb/mongodb-service.yaml

kubectl apply -f kubernetes/backend/backend-secret.yaml
kubectl apply -f kubernetes/backend/backend-configmap.yaml
kubectl apply -f kubernetes/backend/backend-envfile-configmap.yaml
kubectl apply -f kubernetes/backend/backend-deployment.yaml
kubectl apply -f kubernetes/backend/backend-service.yaml

echo "Waiting for app pods..."
kubectl wait -n muchtodo --for=condition=Ready pod -l app=mongodb --timeout=180s
kubectl wait -n muchtodo --for=condition=Ready pod -l app=backend --timeout=180s

echo "Installing ingress-nginx (kind)..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "Applying ingress..."
kubectl apply -f kubernetes/ingress.yaml

echo "Done."
echo "NodePort test: curl -i http://localhost:30080/health"
echo "Ingress test (after /etc/hosts): curl -i http://muchtodo.local/health"

