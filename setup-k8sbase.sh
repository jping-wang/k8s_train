#!/bin/bash

if [ -z $1 ]; then
  echo "Please specify hostname, e.g. 'master', 'node1', 'node2'"
  exit;
fi

yum install -y screen yum-utils device-mapper-persistent-data lvm2 \
	git wget bind-utils mysql net-tools nfs-utils

##### Configure Kernel to see 'bridged' traffic from K8s ####
# Set up required sysctl params, these persist across reboots.
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

##### Docker Runtime #####
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install docker-ce docker-ce-cli containerd.io

# Set up the Docker daemon
mkdir /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
systemctl enable --now docker

#### setup Kubernetes ####
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF



yum -y install kubelet kubeadm kubectl --disableexcludes=kubernetes

### setup Hostname - needed for K8s ###
hostnamectl set-hostname $1

kubectl completion bash > /root/.kubectl.completion.sh
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /root/.bash_profile
echo 'source /root/.kubectl.completion.sh' >> /root/.bashrc

systemctl enable --now kubelet

cat <<EOF > ./final-steps.txt
Now, AFTER you've rebooted this machine, do the following::

1. Pre-pull all the required images
# kubeadm config images pull

2. Ensure the 'lb-k8s' server is running. vi /etc/haproxy/haproxy.cfg to
   set the backend server point to the first Master (master0 IP addr)

3. Initiaze the 1st Master
# kubeadm init --control-plane-endpoint lb-k8s:6443 --upload-certs

Notes:
- can also use --ignore-preflight-errors=all if there's only 1 vcpu)
- remember to edit the /etc/hosts (for ALL masters, and nodes) for 'lb-k8s' IPaddr

4. Create Pod-Network using the 'weave' CNI plugin
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=\$(kubectl version|base64|tr -d '\n')"

EOF


