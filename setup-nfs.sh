#!/bin/bash
mkdir -p /var/export/nfs/{vol1,vol2,vol3,vol4,vol5}
mkdir -p /var/export/nfs/volset{01,02,03,04}
chown -R nfsnobody:nfsnobody /var/export/nfs/
chmod 700 /var/export/nfs/*

cat > /etc/exports <<EOF
/var/export/nfs/vol1 *(rw,async,all_squash)
/var/export/nfs/vol2 *(rw,async,all_squash)
/var/export/nfs/vol3 *(rw,async,all_squash)
/var/export/nfs/vol4 *(rw,async,all_squash)
/var/export/nfs/vol5 *(rw,async,all_squash)
/var/export/nfs/volset01 *(rw,async,all_squash)
/var/export/nfs/volset02 *(rw,async,all_squash)
/var/export/nfs/volset03 *(rw,async,all_squash)
/var/export/nfs/volset04 *(rw,async,all_squash)
EOF

exportfs -a
systemctl enable --now nfs
showmount -e

