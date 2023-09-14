#ssh to Kubernetes mster


#NFS Server setup
#Log into your storage vm
ssh id@***.***.***.***


#Install NFS Server (More info: https://ubuntu.com/server/docs/service-nfs)
#Install NFS Server and create the directory for our exports
sudo apt install nfs-kernel-server -y

sudo mkdir -p /export/volumes
sudo mkdir -p /export/volumes/dynamic1

#Configure our NFS Export in /etc/export for /export/volumes. Using no_root_squash and no_subtree_check to 
#allow applications to mount subdirectories of the export directly.
sudo bash -c 'echo "/export/volumes  *(rw,no_root_squash,no_subtree_check)" > /etc/exports'
cat /etc/exports
sudo systemctl restart nfs-kernel-server.service
exit #Exit your storage server and return to Kubernetes workker node

#Test
sudo apt install nfs-common -y
#Test out basic NFS access before moving on.
sudo mount -t nfs4 192.168.0.14:/export/volumes /mnt/
mount | grep nfs
sudo umount /mnt

#Install NFS dynamic provisioner (https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)
#Install "nfs-subdir-external-provisioner" dynamic provisioner therough "helm". 
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=192.168.0.14 \
    --set nfs.path=/export/volumes/dynamic1


    #To uninstall "nfs-subdir-external-provisioner"
    #helm delete nfs-subdir-external-provisioner

#Check what is installed as part of above dynamic provisioner
kubectl get deployments
kubectl get pods -o wide

#Check again if we have any any SC, PVC, or PV: 
kubectl get StorageClass    

#Make "nfs-client" class as deafult storage class 
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    #To remove "nfs-client" as the default 
    kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

