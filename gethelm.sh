#!/bin/bash
wget https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz
tar zxvf helm*.tar.gz
cd linux-amd64/
cp helm /usr/local/bin
which helm

