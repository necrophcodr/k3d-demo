#!/usr/bin/env bash

CLUSTER=$1
KUBECONFIG=$2
IMAGE=$3
export KUBECONFIG

fail() {
    echo $2
    exit $1
}

set -e
set -x
echo "Importing image ${IMAGE} into ${CLUSTER} using kubeconfig file ${KUBECONFIG}"
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep ${IMAGE}; then 
    echo "Image ${IMAGE} not found. Trying 'docker pull'..."
    docker pull ${IMAGE} || fail $? "Could not pull image ${IMAGE}! Exiting..."
fi
k3d image import --cluster ${CLUSTER} ${IMAGE}