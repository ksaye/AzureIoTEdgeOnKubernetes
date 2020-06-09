#!/usr/bin/env bash

echo "Setting up a Kubernetes Worker Node"
export DEBIAN_FRONTEND=noninteractive

echo "Installing the Prerequisites"
sudo apt update 
sudo apt install -y unzip tree apt-transport-https jq curl wget docker.io </dev/null
systemctl enable docker.service

swapoff -a
sed -i -e '/swap.img/d' /etc/fstab

echo "Installing Kubernetes Only"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
apt-add-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"
apt-get install kubeadm -y </dev/null
