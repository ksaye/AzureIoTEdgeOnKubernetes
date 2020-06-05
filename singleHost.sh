#!/usr/bin/env bash

echo "Parameters Passed:"
echo "krbuser=$krbuser"
echo "DEBIAN_FRONTEND=n$DEBIAN_FRONTEND"
echo "constr=$constr"

echo "Installing the pre requisites"
sudo apt update 
sudo apt install -y k3d unzip tree jq curl wget </dev/null

echo "Installing Microsoft's Moby Runtime"
curl https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list > ./microsoft-prod.list
sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/
sudo apt-get update 
sudo apt-get install -y moby-engine moby-cli </dev/null

echo "Installing Kubectl"
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.17.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

echo "Install K9s (visual cluster explorer)"
wget https://github.com/derailed/k9s/releases/download/v0.15.2/k9s_Linux_x86_64.tar.gz
tar xvf ./k9s_Linux_x86_64.tar.gz
mv ./k9s /usr/local/bin/
rm ./k9s_Linux_x86_64.tar.gz ./LICENSE ./README.md

echo "Install Helm 3"
wget https://get.helm.sh/helm-v3.1.0-linux-amd64.tar.gz
tar xvf ./helm-v3.1.0-linux-amd64.tar.gz
sudo mv ./linux-amd64/helm /usr/local/bin
rm -rf ./linux-amd64/

echo "Wait for docker daemon to start"
while [ $(ps -ef | grep -v grep | grep docker | wc -l) -le 0 ]; do 
sleep 3
done

echo "Download and bootstrap k3d cluster"
sudo k3d delete -n k3s1
wget -q -O - https://raw.githubusercontent.com/rancher/k3d/master/install.sh | TAG=v1.6.0 bash
sudo k3d create -n k3s1 -w 1 --image rancher/k3s:v1.17.2-k3s1 --server-arg \"--no-deploy=traefik\"

sleep 30

echo "Set default KUBECONFIG"
mkdir /home/$krbuser/.kube
cat $(sudo k3d get-kubeconfig --name=''k3s1'') > /home/$krbuser/.kube/config

sleep 5

echo "Install IoT Edge and your Connection String"
sudo kubectl create ns iotedge --kubeconfig=/home/$krbuser/.kube/config
sudo helm install --repo https://edgek8s.blob.core.windows.net/staging edge-crd edge-kubernetes-crd --kubeconfig=/home/$krbuser/.kube/config
sudo helm install --repo https://edgek8s.blob.core.windows.net/staging edge2 edge-kubernetes --namespace iotedge --kubeconfig=/home/$krbuser/.kube/config --set 'provisioning.deviceConnectionString=$constr'
