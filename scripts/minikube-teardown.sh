#!/bin/bash
echo "Tearing down houston-cv from minikube..."
kubectl delete -k k8s/overlays/dev/ --ignore-not-found
echo "Done. Images remain cached in minikube."
