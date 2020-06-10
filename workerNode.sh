#!/usr/bin/env bash

echo "Setting up a Kubernetes Worker Node"
export DEBIAN_FRONTEND=noninteractive

echo "adding the repositories"
sudo apt update && sudo apt install curl apt-transport-https -y
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
apt-add-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"
curl https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list > ./microsoft-prod.list
sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/

echo "Installing the Prerequisites"
sudo apt update 
sudo apt install -y moby-engine moby-cli kubeadm </dev/null

swapoff -a
sed -i -e '/swap.img/d' /etc/fstab
