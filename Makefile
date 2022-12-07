.ONESHELL:=
.DEFAULT_GOAL:=up

CLUSTER:=k3d-server

STATE:=.state
STATEF:=.state/.keepme

DEPLOY:=virtualbox
ENV:=stage
#TAG:="$(shell git branch --no-color --show-current)-$(shell git rev-parse HEAD)"

DEPS_NIX:=$(shell find nix -type f -iname '*.nix')
DEPS_FLAKE:=flake.nix flake.lock

-include: local.mk

$(STATEF):
	mkdir -p $(STATE)
	touch $@

$(STATE)/ssh-config: $(STATE)/$(DEPLOY)-ssh-config $(STATEF)
	cp -L $(STATE)/$(DEPLOY)-ssh-config $@

$(STATE)/virtualbox-ssh-config: $(DEPS_NIX) $(DEPS_FLAKE) $(STATEF)
	vagrant up
	vagrant ssh-config > $@

$(STATE)/local-ssh-config: $(STATEF)
	touch $@

$(STATE)/vm-revision: $(STATE)/$(DEPLOY)-vm-revision $(STATEF)
	cp -L $(STATE)/$(DEPLOY)-vm-revision $@

$(STATE)/virtualbox-vm-revision: $(STATE)/ssh-config $(STATEF)
	NIX_SSHOPTS="-F $(STATE)/ssh-config" SSH_CONFIG_FILE="$(STATE)/ssh-config" colmena apply
	NIX_SSHOPTS="-F $(STATE)/ssh-config" SSH_CONFIG_FILE="$(STATE)/ssh-config" colmena exec -- "readlink -f /nix/var/nix/profiles/system > /vagrant/$@"

$(STATE)/local-vm-revision: $(STATEF)
	touch $@

$(STATE)/virtualbox-kubeconfig: $(STATE)/virtualbox-vm-revision $(STATEF)
	NIX_SSHOPTS="-F $(STATE)/ssh-config" SSH_CONFIG_FILE="$(STATE)/ssh-config" colmena exec --on k3d-server -- bash /vagrant/shell/make-k3d-cluster.sh $(CLUSTER) /vagrant/$@
	sed -i 's|server: https://0\.0\.0\.0|server: https://192.168.57.51|g' $@

$(STATE)/local-kubeconfig:  $(STATEF)
	bash /vagrant/shell/make-k3d-cluster.sh $(CLUSTER) /vagrant/$@

$(STATE)/kubeconfig: $(STATE)/$(DEPLOY)-kubeconfig $(STATEF)
	cp -L $(STATE)/$(DEPLOY)-kubeconfig $@

tf/terraform.tfstate: $(STATE)/kubeconfig $(shell find tf -type f -iname '*.tf') $(shell find kube/values -type f -iname '*.yaml') $(shell find tf/$(ENV).tfvars) tf/.terraform.lock.hcl
	( cd tf && terraform init && terraform apply -var env=$(ENV) -var-file=$(ENV).tfvars)

clean:
	vagrant destroy -f
	rm -rf -- .state
	rm -rf -- .vagrant
	rm -rf -- tf/terraform.tfstate

up: $(STATE)/kubeconfig tf/terraform.tfstate