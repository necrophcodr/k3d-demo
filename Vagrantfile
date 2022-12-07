# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "griff/nixos-stable-x86_64"
  config.vm.box_check_update = false
  config.vm.define "k3d-server" do |server|
    server.vm.network "private_network",
      name: "vboxnet1",
      ip: "192.168.57.51"
    server.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
    end
  end
  config.vm.define "ldap-server" do |server|
    server.vm.network "private_network",
      name: "vboxnet1",
      ip: "192.168.57.10"
    server.vm.provider "virtualbox" do |vb|
      vb.memory = "256"
    end
  end
end
