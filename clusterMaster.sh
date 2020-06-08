#!/usr/bin/env bash

echo "Setting up a Kubernetes Master Host"
echo "Parameters Passed:"
echo "  constr=$constr"

export constr=$constr
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

echo "Installing Kubernetes"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
apt-add-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"
swapoff -a
apt-get install kubeadm -y </dev/null
kubeadm init --pod-network-cidr=172.29.0.0/24 --ignore-preflight-errors=all

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

echo "Install IoT Edge and your Connection String"
kubectl delete ns iotedge --kubeconfig=/etc/kubernetes/admin.conf
kubectl create ns iotedge --kubeconfig=/etc/kubernetes/admin.conf
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml --kubeconfig=/etc/kubernetes/admin.conf
helm install --repo https://edgek8s.blob.core.windows.net/staging edge-crd edge-kubernetes-crd --kubeconfig=/etc/kubernetes/admin.conf
helm install --repo https://edgek8s.blob.core.windows.net/staging edge edge-kubernetes --namespace iotedge --kubeconfig=/etc/kubernetes/admin.conf --set provisioning.deviceConnectionString=$constr

export tokenHash=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
export token=$(kubeadm token list -o json | jq -r .token)
export IPAddress=$(hostname -I | cut -d' ' -f1)

clear
echo
echo

echo Done! you can see the status by running the following command, once you have worker nodes:
echo   kubectl get pods -n iotedge --kubeconfig=/etc/kubernetes/admin.conf

echo To see the visual UI, run:
echo   k9s -n iotedge --kubeconfig=/etc/kubernetes/admin.conf
echo
echo
echo on a worker node, run the following to install Kubernetes:
echo   wget -q -O - https://raw.githubusercontent.com/ksaye/AzureIoTEdgeOnKubernetes/master/workerNode.sh | sudo bash
echo
echo and then run the following command to join this cluster:
echo   kubeadm join $IPAddress:6443 --token $token --discover-token-ca-cert-hash sha256:$tokenHash
