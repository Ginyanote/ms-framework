#Save directory in variable
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

#Download and install K3s, then create a single node cluster
curl -sfL https://get.k3s.io | sh -

#Download Linkerd and install onto Cluster
linkerd
if [ $? -eq 0 ]; then
   echo Linkerd already installed
else
   curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
fi

export PATH=$PATH:/root/.linkerd2/bin
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -

#Install Helm if not present
helm
if [ $? -eq 0 ]; then
   echo Helm already installed
else
   curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
   sudo apt-get install apt-transport-https --yes
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
   sudo apt-get update
   sudo apt-get install helm
fi

#Wait for availability of CRDs in the cluster
counter=1
retries=10
sleeptime=10
while [ $counter -le $retries ]
do
   ((counter++))
   kubectl get ingressroute
   if [ $? -eq 0 ]; then
      break
   else
      if [ $counter -eq $retries ]; then
         echo CRDs are not yet available, please install helm-chart manually
         exit 1
      fi
      echo CRDs not yet ready, retrying in $sleeptime seconds
      sleep $sleeptime
   fi
done

#Install Helm-Chart
helm install helm-msa $SCRIPT_DIR/helm/helm-msa
