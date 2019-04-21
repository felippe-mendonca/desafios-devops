#!/bin/bash 

if [ "$#" -ne 1 ]; then
  operation="install"
else
  operation=$1
  if [ "${operation}" != "install" ] && [ "$operation" != "delete" ]; then
    echo "Invalid operation. Use 'install' or 'delete'."
    exit 1
  fi
fi

if [ ${operation} == "install" ]; then
  helm install helm-charts/greeter-app    \
    --values helm-values/greeter-app.yaml \
    --namespace greeter-app-ns            \
    --name greeter-app
else
  helm delete greeter-app --purge
fi