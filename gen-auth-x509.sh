#!/bin/bash

USER=$1  # name of the user, key, csr and certificate
GROUP=$2 # Group ID
DAYS=$3
BITS=2048

if [[ "$#" -lt 2 ]]; then
    echo "Usage: $0 user group DAYS"
    exit 1
fi
if [ $DAYS=='' ]; then 
     DAYS=365
fi
CPATH=/home
CA_PATH=/etc/kubernetes/pki
CA_CERT=$CA_PATH/ca.crt
CA_KEY=$CA_PATH/ca.key
CLIENT_KEY=$CPATH/$USER/$USER.key
CLIENT_CSR=$CPATH/$USER/$USER.csr
CLIENT_CRT=$CPATH/$USER/$USER.crt

CLUSTERENDPOINT=$(kubectl config view | grep server | cut -f 2- -d ":" | tr -d " ")
CLUSTERNAME=$(kubectl config get-clusters | sed -n '2p') 

useradd -m ${USER} 
mkdir -p $CPATH/$USER/.kube && cd $CPATH/$USER
openssl genrsa -out $CLIENT_KEY 4096
openssl req -new -key $CLIENT_KEY -out $CLIENT_CSR -subj "/O=$GROUP/CN=$USER"
openssl x509 -req -days $DAYS -sha256 -in $CLIENT_CSR -CA $CA_CERT -CAkey $CA_KEY -set_serial 2 -out $CLIENT_CRT

cat <<-EOF > $CPATH/$USER/.kube/config
apiVersion: v1
kind: Config
preferences:
  colors: true
current-context: $CLUSTERNAME
clusters:
- name: $CLUSTERNAME
  cluster:
    server: $CLUSTERENDPOINT
    certificate-authority-data: $(cat $CA_CERT | base64 --wrap=0)
contexts:
- context:
    cluster: $CLUSTERNAME
    user: $USER
  name: $CLUSTERNAME
users:
- name: $USER
  user:
    client-certificate-data: $(cat $CLIENT_CRT | base64 --wrap=0)
    client-key-data: $(cat $CLIENT_KEY | base64 --wrap=0)
EOF

chown -R $USER:$USER /home/$USER

