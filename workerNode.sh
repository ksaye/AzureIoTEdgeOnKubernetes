#!/usr/bin/env bash

echo "Setting up a Kubernetes Master Host"
export DEBIAN_FRONTEND=noninteractive

echo "Installing the Prerequisites"
sudo apt update 
sudo apt install -y unzip tree apt-transport-https jq curl wget </dev/null

echo "Installing Microsoft's Moby Runtime"
curl https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list > ./microsoft-prod.list
sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/
sudo apt-get update 
sudo apt-get install -y moby-engine moby-cli </dev/null

echo "Installing Kubernetes Only"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
apt-add-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"
swapoff -a
apt-get install kubeadm -y </dev/null
