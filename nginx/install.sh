#!/usr/bin/env bash
# Install/upgrade ingress-nginx on NHN NKS (staging) with a pinned chart version.
#   KUBE_CONTEXT=<context> bash nginx/install.sh
# KUBE_CONTEXT is required on purpose, so this never lands on the wrong cluster.
# Check what is deployed first: helm --kube-context "$KUBE_CONTEXT" -n ingress-nginx list
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${KUBE_CONTEXT:?set KUBE_CONTEXT to the target cluster context}"
# 4.15.1 is the final community release (controller v1.15.1). No floating "latest".
: "${INGRESS_NGINX_CHART_VERSION:=4.15.1}"

kubectl --context "$KUBE_CONTEXT" cluster-info >/dev/null || { echo "context not reachable"; exit 1; }
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update ingress-nginx >/dev/null

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --version "$INGRESS_NGINX_CHART_VERSION" \
  --kube-context "$KUBE_CONTEXT" \
  --namespace ingress-nginx --create-namespace \
  -f "$DIR/nginx-values.yaml" \
  --wait --timeout 10m
