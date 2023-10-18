#!/bin/sh
apt-get update -q
apt --yes install \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    curl
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update -q
swapoff -a
sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update -q
apt-get install -y containerd
rm /etc/containerd/config.toml
systemctl restart containerd
apt-get install -q -y ebtables ethtool
apt-get install -q -y apt-transport-https
tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
modprobe br_netfilter
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
echo net.ipv6.conf.all.disable_ipv6=1 | tee -a /etc/sysctl.conf
echo net.ipv6.conf.default.disable_ipv6=1 | tee -a /etc/sysctl.conf
echo net.ipv6.conf.lo.disable_ipv6=1 | tee -a /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl net.bridge.bridge-nf-call-iptables=1