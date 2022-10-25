curl -sfL https://get.k3s.io | sh -

curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh

export PATH=$PATH:/root/.linkerd2/bin
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -