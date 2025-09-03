#!/bin/bash

################################################
# Environment parameters from script arguments #
################################################
BuildDirectory=$1
location=$2
appName=$3
SubscriptionId=$4
#envName=$5
appEnv=$5
hostEnv=$6
tierName=$7
size=$8
ArtifactPathContainerApp=$9
shortTierName=${10}
envName=${11}
#ResourceGroupName="persistent-${appName}-ta-sn-${tierName}-${envName}-eu"
#ResourceGroupName="persistent-aks-ta-${tierName}-${envName}-eu"
#AksClusterName="aks-${tierName}-${envName}-${location}"
ResourceGroupName="persistent-aks-ta-${appEnv}-${hostEnv}-${location}"
AksClusterName="aks-${appEnv}-${hostEnv}-${location}"

#workloadIdentityName=aks-${appName}-${appEnv}-${hostEnv}-${region}-msi
isNetworkPolicyEnabled="false"

DaResourceGroupName=persistent-${appName}-sn-${appEnv}-${hostEnv}-${location}
az account set --subscription $SubscriptionId
#daAssetVal=$(az aks show --resource-group $ResourceGroupName --name $AksClusterName --query tags -o json | jq '.["deployable-asset"]')
daAssetVal=$(az group show --name $DaResourceGroupName --query tags -o json | jq '.["deployable-asset"]')
#appEnvVal=$(az aks show --resource-group $ResourceGroupName --name $AksClusterName --query tags -o json | jq '.["applicationEnvironment"]')
appEnvVal=$(az group show --name $DaResourceGroupName --query tags -o json | jq '.["applicationEnvironment"]')
daId=${daAssetVal//\"/}
appEnv=${appEnvVal//\"/}
appEnv=`echo $appEnv|tr '[:upper:]' '[:lower:]'` 
echo "deployable asset id: $daId"
echo "application environment name: $appEnv"

namespace=${daId}-${appEnv}
echo "namespace for deployable asset: $namespace"
saName=${appName}-${appEnv}-sa


echo "parameters BuildDirectory: $BuildDirectory, location=$location, appName=$appName, SubscriptionId=$SubscriptionId, appName=$appvName,  tierName=$tierName, size=$size, namespace=$namespace, Artifact=$ArtifactPathContainerApp"



create_namespace_apply_resource() {
    az account set --subscription $SubscriptionId
    az aks get-credentials --resource-group $ResourceGroupName --name $AksClusterName --overwrite-existing --admin

    echo "getting workload identity client id"
   
    get_workload_identity_details
    

    helm upgrade --install $chartName $TmpdDirectory/$chartFileName --set "resourceQuotas.type=$size","networkPolicy.enabled=$isNetworkPolicyEnabled","namespace.name=$namespace","serviceAccount.name=$saName","serviceAccount.annotations.azure\.workload\.identity/client-id=$workloadIdentityId" -n $namespace --create-namespace

}

get_workload_identity_details() {
    
    identityId=$(az identity list --resource-group $DaResourceGroupName --query "[].{Id:id}" -o tsv)
    workloadIdentityId=$(az identity show --ids $identityId --query "clientId" -o tsv)
    echo "client id for the workload identity: $workloadIdentityId"

    workloadIdentityName=$(az identity list --resource-group $DaResourceGroupName --query "[].{Name:name}" -o tsv)
    echo "name for the workload identity: $workloadIdentityName"


}

workload_identity_federation() {
federatedIdentityCredentialName=${appName}-federated-identity
oidcURL=$(az aks show --resource-group $ResourceGroupName --name $AksClusterName --query "oidcIssuerProfile.issuerUrl" -o tsv)


az identity federated-credential create --name ${federatedIdentityCredentialName} \
    --identity-name $workloadIdentityName \
    --resource-group $DaResourceGroupName \
    --issuer $oidcURL \
    --subject system:serviceaccount:"$namespace":"$saName" \
    --audience api://AzureADTokenExchange

}




user=`whoami`
if [ $user == "root" ]; then
    export KUBECONFIG=/root/.kube/config
    
  
else
    export KUBECONFIG=/home/$user/.kube/config


fi


mkdir -p "/tmp/akstools"
if [ $? -ne 0 ]; then
    echo "unable to create /tmp/akstools"
    exit 1
else 
    TmpdDirectory="/tmp/akstools"
fi

export PATH=$PATH:/usr/local/bin


HelmChart=($namespace "container-app" $ArtifactPathContainerApp )

artifactoryDomain="artifacts.eastus.az.mastercard.int"
artifactPath="archive-internal-unstable/com/mastercard/claas/helm-charts"

namespace=${HelmChart[0]}
chartName=${HelmChart[1]}
artifact=${HelmChart[2]}
echo $artifact
chartPath="https://${artifactoryDomain}/artifactory/${artifactPath}/${artifact}"
echo "$chartPath"
chartFileName=$(basename "$chartPath")
echo $chartFileName

curl -o $TmpdDirectory/$chartFileName $chartPath --insecure

if [ $? -ne 0 ]; then

    echo "Chart retrieval failed: $chartFileName from $chartPath"
    exit 1
    
fi 

create_namespace_apply_resource
echo "federating the workload identity"
workload_identity_federation

 




