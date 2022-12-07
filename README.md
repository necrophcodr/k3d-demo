# k3d-demo

This is a simple demonstration of running k3d via Vagrant with LDAP setup for ArgoCD as well as a simple demo deployment of the RabbitMQ Cluster Operator via Kustomize as an ArgoCD Application.

Please feel free to fork this to your hearts contents and use as a VERY basic template to build upon.

Included is a Nix Flake for setting up a development and deployment shell, as well as a Makefile that handles the full deployment.

`make` takes two parameters (which can be specified locally in a local.mk file as well):

* `DEPLOY`, which must be either "virtualbox" (for vagrant deployment) or "local" (for avoiding vagrant entirely, and use a local docker host), and
* `ENV`, which must be one of "demo", "stage", or "prod". Only "demo" is implemented as inspiration for the remaining parts.