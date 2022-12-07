#!/usr/bin/env bash

CLUSTER=$1
KUBECONFIG=$2
export KUBECONFIG

echo "Creating cluster ${CLUSTER} in ${KUBECONFIG}"

if k3d cluster list | grep ${CLUSTER}; then
    k3d kubeconfig get ${CLUSTER} > ${KUBECONFIG}
else
    k3d cluster create --wait -p "80:80@loadbalancer" \
        --servers 1 \
        --agents 1 \
        --timeout 120s \
        --no-rollback \
        --volume /vagrant/data:/var/lib/rancher/k3s/storage \
        --k3s-arg "--disable=traefik@server:0" \
        --k3s-arg "--tls-san=192.168.57.51@server:*" \
        --api-port "0.0.0.0:6443" \
        --wait \
        ${CLUSTER}
    k3d kubeconfig get ${CLUSTER} > ${KUBECONFIG}
fi