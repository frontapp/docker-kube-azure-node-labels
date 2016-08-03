#!/bin/sh

INSTANCE_INFO=`curl -s http://169.254.169.254/metadata/v1/InstanceInfo`
UPDATE_DOMAIN=`echo ${INSTANCE_INFO} | jq --raw-output '.UD'`
FAULT_DOMAIN=`echo ${INSTANCE_INFO} | jq --raw-output '.FD'`

# It appears it takes a while for the pod to incorporate the node name.
while [ "x$NODE" = "x" ] || [ "$NODE" = "null" ]; do
  sleep 1
  echo "[$(date)] Pod: $POD_NAME"
  NODE=`curl  -s -f \
        --cert   /etc/kubernetes/ssl/worker.pem \
        --key    /etc/kubernetes/ssl/worker-key.pem \
        --cacert /etc/kubernetes/ssl/ca.pem  \
        https://${KUBERNETES_SERVICE_HOST}/api/v1/namespaces/kube-system/pods/${POD_NAME} | jq -r '.spec.nodeName'
  `
done

echo "[$(date)] Node: $NODE"

curl  -s \
      --cert   /etc/kubernetes/ssl/worker.pem \
      --key    /etc/kubernetes/ssl/worker-key.pem \
      --cacert /etc/kubernetes/ssl/ca.pem  \
      --request PATCH \
      -H "Content-Type: application/strategic-merge-patch+json" \
      -d @- \
      https://${KUBERNETES_SERVICE_HOST}/api/v1/nodes/${NODE} <<EOF
{
  "metadata": {
    "labels": {
      "azure.node.kubernetes.io/update_domain": "${UPDATE_DOMAIN}",
      "azure.node.kubernetes.io/fault_domain": "${FAULT_DOMAIN}"
    }
  }
}
EOF
