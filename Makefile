.ONESHELL:=
.DEFAULT_GOAL:=up

CLUSTER:=k3d-server

DEPLOY:=virtualbox
ENV:=stage
#TAG:="$(shell git branch --no-color --show-current)-$(shell git rev-parse HEAD)"

DEPS_NIX:=$(shell find nix -type f -iname '*.nix')
DEPS_FLAKE:=flake.nix flake.lock

-include local.mk

STATE:=.state
STATEF:=.state/.keepme
IMAGES:=$(shell find kube/images/$(ENV) -type f -not -name '.keepme')
IMAGES_TARGETS:=$(shell find kube/images/$(ENV) -type f -not -name '.keepme' -printf '$(STATE)/$(ENV)-$(DEPLOY)-image-%f\n')

$(info Deployment: $(DEPLOY))
$(info Environment: $(ENV))

$(STATEF):
	mkdir -p $(STATE)
	touch $@

$(STATE)/$(ENV)-ssh-config: $(STATE)/$(ENV)-$(DEPLOY)-ssh-config $(STATEF)
	cp -L $(STATE)/$(ENV)-$(DEPLOY)-ssh-config $@

$(STATE)/$(ENV)-virtualbox-ssh-config: $(DEPS_NIX) $(DEPS_FLAKE) $(STATEF)
	vagrant up
	vagrant ssh-config > $@

$(STATE)/$(ENV)-local-ssh-config: $(STATEF)
	touch $@

$(STATE)/$(ENV)-vm-revision: $(STATE)/$(DEPLOY)-vm-revision $(STATEF)
	cp -L $(STATE)/$(ENV)-$(DEPLOY)-vm-revision $@

$(STATE)/$(ENV)-virtualbox-vm-revision: $(STATE)/$(ENV)-ssh-config $(STATEF)
	NIX_SSHOPTS="-F $(STATE)/$(ENV)-ssh-config" SSH_CONFIG_FILE="$(STATE)/$(ENV)-ssh-config" colmena apply
	NIX_SSHOPTS="-F $(STATE)/$(ENV)-ssh-config" SSH_CONFIG_FILE="$(STATE)/$(ENV)-ssh-config" colmena exec --on k3d-server -- "readlink -f /nix/var/nix/profiles/system > /vagrant/$@"

$(STATE)/$(ENV)-local-vm-revision: $(STATEF)
	touch $@

$(STATE)/$(ENV)-virtualbox-kubeconfig: $(STATE)/$(ENV)-virtualbox-vm-revision $(STATEF)
	NIX_SSHOPTS="-F $(STATE)/$(ENV)-ssh-config" SSH_CONFIG_FILE="$(STATE)/$(ENV)-ssh-config" colmena exec --on k3d-server -- bash /vagrant/shell/make-k3d-cluster.sh $(CLUSTER) /vagrant/$@
	sed -i 's|server: https://0\.0\.0\.0|server: https://192.168.57.51|g' $@

$(STATE)/$(ENV)-local-kubeconfig: $(STATEF)
	bash shell/make-k3d-cluster.sh $(CLUSTER) $@

$(STATE)/$(ENV)-kubeconfig: $(STATE)/$(ENV)-$(DEPLOY)-kubeconfig $(STATEF)
	cp -L $(STATE)/$(ENV)-$(DEPLOY)-kubeconfig $@


$(STATE)/kubeconfig: $(STATE)/$(ENV)-kubeconfig
	cp -L $(STATE)/$(ENV)-kubeconfig $@

$(STATE)/$(ENV)-virtualbox-image-%: $(IMAGES) $(STATE)/$(ENV)-kubeconfig
	NIX_SSHOPTS="-F $(STATE)/$(ENV)-ssh-config" SSH_CONFIG_FILE="$(STATE)/$(ENV)-ssh-config" colmena exec --on k3d-server -- bash /vagrant/shell/import-image.sh $(CLUSTER) /vagrant/$(STATE)/kubeconfig $(shell cat kube/images/$(ENV)/$*) && \
	touch $@

$(STATE)/$(ENV)-local-image-%: $(IMAGES) $(STATE)/$(ENV)-kubeconfig
	bash shell/import-image.sh $(CLUSTER) $(STATE)/$(ENV)-kubeconfig $(shell cat kube/images/$(ENV)/$*) && \
	touch $@

$(STATE)/$(ENV)-image-%: $(STATE)/$(ENV)-$(DEPLOY)-images-$*
	cp -L $(STATE)/$(ENV)-$(DEPLOY)-images-$* $@

tf/.terraform.lock.hcl: $(STATE)/kubeconfig $(shell find tf -type f -iname '*.tf') $(DEPS_FLAKE)
	( cd tf && terraform init )

tf/terraform.tfstate: $(STATE)/kubeconfig $(IMAGES_TARGETS) $(shell find tf -type f -iname '*.tf') $(shell find kube/values -type f -iname '*.yaml') $(shell find tf/$(ENV).tfvars) tf/apps/$(ENV).yaml tf/.terraform.lock.hcl
	( cd tf && terraform apply -var env=$(ENV) -var-file=$(ENV).tfvars)
	kubectl wait --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-dex-server --timeout=2m
	kubectl patch configmaps argocd-cm --patch-file kube/argocd-cm-patch.yaml
	kubectl delete pod argo-cd-argocd-application-controller-0

$(STATE)/$(ENV)-$(DEPLOY)-argocd: tf/terraform.tfstate kube/argocd-cm-patch.yaml
	touch $@

clean:
	vagrant destroy -f
	rm -rf -- .state
	rm -rf -- .vagrant
	rm -rf -- tf/terraform.tfstate*
	rm -f -- tf/.terraform.lock.hcl
	rm -rf -- tf/.terraform/

up: $(STATE)/$(ENV)-kubeconfig $(IMAGES_TARGETS) tf/terraform.tfstate $(STATE)/$(ENV)-$(DEPLOY)-argocd