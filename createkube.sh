az account set --subscription "4c8f59f4-f6e0-4e62-ba6e-eb97a2e6c9bc"
RG=NetworkLab
LOC=eastus
VNET_CIDR="10.220.0.0/16"
KUBENET_AKS_CIDR="10.220.1.0/24"
AZURECNI_AKS_CIDR="10.220.2.0/24"
SVC_LB_CIDR="10.220.3.0/24"

# Create Resource Group
az group create -n $RG -l $LOC

# Create Vnet
az network vnet create \
-g $RG \
-n aksvnet \
--address-prefix $VNET_CIDR

# Create Kubenet AKS Cluster Subnet
az network vnet subnet create \
    --resource-group $RG \
    --vnet-name aksvnet \
    --name kubenet \
    --address-prefix $KUBENET_AKS_CIDR

# Get the Kubenet Subnet ID
KUBENET_SUBNET_ID=$(az network vnet show -g $RG -n aksvnet -o tsv --query "subnets[?name=='kubenet'].id")

# Create Azure CNI AKS Cluster Subnet
az network vnet subnet create \
    --resource-group $RG \
    --vnet-name aksvnet \
    --name azurecni \
    --address-prefix $AZURECNI_AKS_CIDR

# Create the subnet for Kubernetes Service Load Balancers
az network vnet subnet create \
    --resource-group $RG \
    --vnet-name aksvnet \
    --name services \
    --address-prefix $SVC_LB_CIDR


######################################
# Create the Kubenet AKS Cluster
# Note: We set a pod cidr, service cidr
# and dns service ip for demonstration
# purposes, however these are optional
#######################################
az aks create \
-g $RG \
-n kubenet-cluster \
--network-plugin kubenet \
--vnet-subnet-id $KUBENET_SUBNET_ID \
--pod-cidr "10.100.0.0/16" \
--service-cidr "10.200.0.0/16" \
--dns-service-ip "10.200.0.10" \
--enable-managed-identity
--generate-ssh-keys

# Get Credentials
az aks get-credentials -g $RG -n kubenet-cluster

# Get the deployment manifest
wget https://raw.githubusercontent.com/swgriffith/azure-guides/master/networking-overview/nginx.yaml

# Deploy 3 Nginx Pods across 3 nodes
kubectl apply -f nginx.yaml

# View the Services and pods
kubectl get svc
kubectl get pods -o wide --sort-by=.spec.nodeName # Sorted by node name

