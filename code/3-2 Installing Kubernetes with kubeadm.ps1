# Install the k8s (kubernetes) CLI
choco install kubernetes-cli -y 

# I have prepared a script for the k8s basisc
code $home\desktop\code\k8s\PrepareKubernetes.sh

# This function will run a file on a Linux machine
function RunFileOnLinux {
  param (
      $File,
      $Tgt
  )
  $TgtFile=$tgt + ":~/RunScript.sh"
  scp $File $TgtFile
  ssh -t $tgt 'chmod +x ~/RunScript.sh; dos2unix ~/RunScript.sh; sudo ~/RunScript.sh'
}

# Let's setup our basics on the control plane
RunFileOnLinux -File ($Home + '\desktop\code\k8s\PrepareKubernetes.sh') -Tgt 'demo@k8s-cp'

# SSH into CP
ssh demo@k8s-cp

# Get kubeadm version
kubeadm version

# Init cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.27.3

# Get config
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u $USER):$(id -g $USER) $HOME/.kube/config

# Check nodes
kubectl get nodes

exit

# Copy config from Control Plane
mkdir $home/.kube
scp "demo@k8s-cp:~/.kube/config" $home/.kube/config

# We can now manage our cluster from here:
kubectl get nodes

# Storage
# NFS
kubectl apply -f $home\desktop\code\k8s\nfs-rbac.yaml
kubectl apply -f $home\desktop\code\k8s\nfs-storageclass.yaml
code $home\desktop\code\k8s\nfs-provisioner.yaml
kubectl apply -f $home\desktop\code\k8s\nfs-provisioner.yaml -n default
kubectl get sc

# Local Storage
kubectl apply -f $home\desktop\code\k8s\local-storage.yaml
kubectl get sc

# Networking
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# And also loadbalancing
# First, change strictARP to true
kubectl edit configmap kube-proxy -n kube-system 
# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.5/config/manifests/metallb-native.yaml -n metallb-system  
# Define an address pool
code $home\desktop\code\k8s\IPAddressPool.yaml
kubectl apply -f $home\desktop\code\k8s\IPAddressPool.yaml
# And announce it
code $home\desktop\code\k8s\L2Advertisement.yaml
kubectl apply -f $home\desktop\code\k8s\L2Advertisement.yaml

# Now let's check our nodes 
kubectl get nodes

## Add worker nodes
# Install Basics on all workers
RunFileOnLinux -File ($Home + '\desktop\code\k8s\PrepareKubernetes.sh') -Tgt 'demo@k8s-worker-1'
RunFileOnLinux -File ($Home + '\desktop\code\k8s\PrepareKubernetes.sh') -Tgt 'demo@k8s-worker-2'

ssh -t demo@k8s-cp 'sudo kubeadm token create --print-join-command'

ssh -t demo@k8s-cp 'sudo kubeadm token create --print-join-command' | Out-File JoinCommand.sh
RunFileOnLinux -File 'JoinCommand.sh' -Tgt 'demo@k8s-worker-1'
RunFileOnLinux -File 'JoinCommand.sh' -Tgt 'demo@k8s-worker-2'


## Or make control plane scheduleable
# $master_node=(kubectl get nodes --no-headers=true --output=custom-columns=NAME:.metadata.name)
# kubectl taint nodes $master_node node-role.kubernetes.io/master:NoSchedule-
# kubectl taint nodes $master_node node-role.kubernetes.io/control-plane:NoSchedule-

kubectl get nodes 
kubectl get nodes -o wide

# Try MetalLB again
kubectl apply -f $home\desktop\code\k8s\IPAddressPool.yaml
kubectl apply -f $home\desktop\code\k8s\L2Advertisement.yaml

kubectl get pv

# Let's create local storage mountpoints
code $home\desktop\code\k8s\PrepareLocalMountpoints.sh
RunFileOnLinux -File ($Home + '\desktop\code\k8s\PrepareLocalMountpoints.sh') -Tgt 'demo@k8s-worker-1'
RunFileOnLinux -File ($Home + '\desktop\code\k8s\PrepareLocalMountpoints.sh') -Tgt 'demo@k8s-worker-2'

kubectl get pv