#!/bin/bash

if [ "$#" -ne 1 ]; then
  operation="apply"
else
  operation=$1
  if [ "${operation}" != "apply" ] && [ "$operation" != "delete" ]; then
    echo "Invalid operation. Use 'apply' or 'delete'."
    exit 1
  fi
fi

namespace_cmd_output=$(kubectl ${operation} -f manifests/namespace.yaml)
namespace_exit_code=$?

if [ ${operation} == "apply" ]; then
  echo  ${namespace_cmd_output}
  kubectl ${operation} -f manifests/deployment.yaml
  kubectl ${operation} -f manifests/service.yaml
  kubectl ${operation} -f manifests/ingress.yaml
  echo "Done."
elif [ ${namespace_exit_code} -eq 0 ]; then
  echo "All resources from ${namespace_cmd_output}."
else
  exit ${namespace_exit_code}
fi

exit 0