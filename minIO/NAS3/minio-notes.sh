#! /bin/bash


helm install minio-putulero --namespace minio-putulero -f minIO/NAS3/helm-minio-putulero.yml minio/minio
helm install minio-skedulosa --namespace minio-skedulosa -f minIO/NAS3/helm-minio-skedulosa.yml minio/minio

kubectl apply -f minIO/NAS3/ingress-minio-putulero.yml -n minio-putulero
kubectl apply -f minIO/NAS3/ingress-minio-skedulosa.yml -n minio-skedulosa