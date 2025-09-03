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
ArtifactPathESO=$7
ArtifactPathNginx=$8
ValuesURLESO=$9
ValuesURLNginx=${10}
tierName=${11}
ArtifactPathPrisma=${12}
shortTierName=${13}
ArtifactPathOperator=${14}
ArtifactPathOneagent=${15}

echo "parameters BuildDirectory: $BuildDirectory, location=$location, \n
appName=$appName, SubscriptionId=$SubscriptionId, envName=$envName,  \n
ArtifactPathESO=$ArtifactPathESO, ArtifactPathNginx=$ArtifactPathNginx, \n
ValuesURLESO=$ValuesURLESO, ValuesURLNginx=$ValuesURLNginx, tierName=$tierName, ArtifactPathPrisma=$ArtifactPathPrisma"

#ResourceGroupName="persistent-${appName}-ta-sn-${tierName}-${envName}-eu"
ResourceGroupName="persistent-aks-ta-${appEnv}-${hostEnv}-${location}"
AksClusterName="aks-${appEnv}-${hostEnv}-${location}"
NamespaceNginx="nginx"
NamespaceESO="external-secrets"
#ArtifactPathESO="external-secrets/external-secrets-0.9.13.tgz"
#ArtifactPathNginx="ingress-controller/ingress-nginx-4.7.3.tgz" 
#ValuesURLESO="external-secrets/work/values-0.0.1.yaml"
#ValuesURLNginx="ingress-controller/nginx-1.9.6-work.yaml"
source /etc/profile.d/vmssvars.sh

sleep 300


#location="eastus"


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
nginxHelmChart=("nginx" "nginx" $ArtifactPathNginx $ValuesURLNginx)
esoHelmChart=("external-secrets"  "eso" $ArtifactPathESO $ValuesURLESO)
prismaHelmChart=("twistlock" "prisma" $ArtifactPathPrisma "")
dtOperatorHelmChart=("dynatrace" "dynatrace-operator" $ArtifactPathOperator "")
dtOneagentHelmChart=("dynatrace" "dynakube" $ArtifactPathOneagent "")

helmCharts=(
        nginxHelmChart
        esoHelmChart
        prismaHelmChart
        dtOperatorHelmChart
        dtOneagentHelmChart
)

get_ip_address_from_vnet() {
    
    echo "getting ip address from the vnet"
    subnetId=$(az aks show --resource-group $ResourceGroupName --name $AksClusterName --query "agentPoolProfiles[0].vnetSubnetId")
    vnetId=$(echo $subnetId | cut -d '/' -f 1-9 | tr -d '"')
    subnetName=$(echo $subnetId |awk -F '/' '{print $NF}' | tr -d '"')
    vnetName=$(az network vnet show --ids $vnetId --query "name" --output tsv)
    vnetRg=$(az network vnet show --ids $vnetId --query "resourceGroup" --output tsv)
    availableIp=$(az network vnet subnet list-available-ips --resource-group $vnetRg --vnet-name $vnetName -n $subnetName --query [0] -o tsv)         
    echo "available ip from the vnet $vnetName: $availableIp"
    echo "checking if nginx load balancer ip exists.."
    assignedIp=$(kubectl get service nginx-ingress-nginx-controller -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' -n nginx --ignore-not-found)
    echo "ip exists: $assignedIp"

    if [ -n $assignedIp ]; then

        lbIp=$assignedIp

    else
        lbIp=$availableIp
           
    fi

}

check_aks_update_status() {
    local ResourceGroupName=$1
    local AksClusterName=$2
    echo "Checking if AKS update is in progress..."
    while true; do
        aks_status=$(az aks show --resource-group $ResourceGroupName --name $AksClusterName --query "provisioningState" -o tsv )
        if [[ "$aks_status" == "Succeeded" ]]; then
            echo "AKS is in 'Succeeded' state. Proceeding with ACR attachment"
            break
        elif [[ "$aks_status" == "Updating" ]]; then
            echo "AKS is in Updating state. Waiting for the update to complete..."
        elif [[ "$aks_status" == "Upgrading" ]]; then
            echo "AKS is in Upgrading state. Waiting for the upgrade to complete..."
        else
            echo "Unexpected AKS provisioning state: $aks_status. Exiting"
            exit 1
        fi
        sleep 30
    done
}

acr_access() {
  #  case $tierName in 

   # "work"|"d"|"dev")
     #       acrSubscription="fb54b7af-4664-46a6-8383-99d0cde54f03" ;;
    #"nonp")
      #      acrSubscription="fb54b7af-4664-46a6-8383-99d0cde54f03" ;;
    #"prod")
       #     acrSubscription="fb54b7af-4664-46a6-8383-99d0cde54f03";;
    # *)
        #    echo "unknown environment for acr" ;;
    #esac       
    
    acrId=$(az acr list --subscription "${tierName}01ACR" --query "[?location=='$location'].{RegistryId:id}" --output tsv)
    echo $acrId
    acrName=$(az acr list --subscription "${tierName}01ACR" --query "[?location=='$location'].{Name:name}" --output tsv)
    echo $acrName

   
    az account set --subscription $SubscriptionId
    aksClientId=$(az aks show --resource-group $ResourceGroupName --name $AksClusterName --query identityProfile.kubeletidentity.clientId -o tsv)
    az account set --subscription "${tierName}01ACR"
    roleVal=$(az role assignment list --all --assignee $aksClientId | jq '.[].roleDefinitionName')
    echo $roleVal
    if [[ -n $roleVal ]]; then
        roleAssigned=${roleVal//\"/}
    else
        roleAssigned=""
    fi
    #roleAssigned=${//roleVal\"/}
    if [[ "$roleAssigned" == "AcrPull" ]]; then
        echo "Role $roleAssigned is already assigned to AKS MSI - $aksClientId"
    else
        echo "Attacing ACR $acrName to AKS Cluster $AksClusterName"
        az account set --subscription $SubscriptionId
        check_aks_update_status "$ResourceGroupName" "$AksClusterName"

        az aks update -g $ResourceGroupName -n $AksClusterName --attach-acr $acrId
        if [ $? -ne 0 ]; then
            echo  echo "unable to attach AKS Cluster $AksClusterName to ACR $acrName"
            exit 1
        else
            echo "attached AKS Cluster $AksClusterName to ACR $acrName"
        fi
    fi
   
}



pull_secrets_from_keyvault() {

   # case $tierName in

    #"dev")
     #   subscription="work01AzureForgePOC" ;;
    #"work"|"d")
     #   subscription="work01AzureForgePOC" ;;
     #"nonp")
      #  subscription="nonp01Infrastructure" ;;
    #"prod")
     #   subscription="prod01Infrastructure" ;;
    #*)
     #   echo "unknown environment for platform" ;;
    #esac

    az account set --subscription ${tierName}01Infrastructure
    keyvaults=$(az keyvault list --query "[?location=='$location'].{Name:name}" -o tsv )
    echo $keyvaults
    for keyvault in $keyvaults; do
        if [[ $keyvault == platform* ]]; then
            platformkv=$keyvault
            echo "Found the keyvault: $platformkv"
        fi
    done

    secretAcr1=$(az keyvault secret show --name acr-helm-pull-secret-password1 --vault-name $platformkv --query value -o tsv) 2>/dev/null
    secretAcr2=$(az keyvault secret show --name acr-helm-pull-secret-password2 --vault-name $platformkv --query value -o tsv) 2>/dev/null
    echo "Getting credentials for AKS cluster $AksClusterName in resource group $ResourceGroupName"
    
    az account set --subscription $SubscriptionId
    az aks get-credentials --resource-group $ResourceGroupName --name $AksClusterName --overwrite-existing --admin
    kubectl create secret generic acr-helm-pull-secret --save-config --dry-run=client --from-literal=password1=$secretAcr1 --from-literal=password2=$secretAcr2 -o yaml | kubectl apply -f - 2>/dev/null
    kubectl get secret acr-helm-pull-secret
    if [ $? -ne 0 ]; then
        echo "secret 'acr-helm-pull-secret'creation failed"
    else
        echo "secret created successfully"
    fi
}

echo "attaching container registry to AKS cluster with acrPull access"
acr_access

artifactoryDomain="artifacts.eastus.az.mastercard.int"
artifactPath="archive-internal-unstable/com/mastercard/claas/helm-charts"
certFullPath="https://artifacts.eastus.az.mastercard.int/artifactory/archive-internal-stable/com/mastercard/builderscloud/jenkins-controller/aks-certs/mcca_add_${tierName}.yml"

is_cert_installed() {
    if kubectl get namespace "mastercard-internal-ca" >/dev/null 2>&1; then
        echo "certificate already installed"
    else
        curl -o $TmpdDirectory/mcca_add.yml $certFullPath --insecure
        kubectl apply -f $TmpdDirectory/mcca_add.yml
        if [ $? -ne 0 ]; then
            echo "failed to install certificate"
        else
            echo "certificate installed"
        fi
    fi
}


echo "pulling secrets from keyvault" 
pull_secrets_from_keyvault


check_and_create_namespace() {
    local namespace=$1
    if kubectl get namespace "$namespace" >/dev/null 2>&1; then
        echo "namepsace $namespace already exists"
    else
        echo "creating namespace $namespace"
        kubectl create namespace "$namespace"
    fi    

}

###### dynatrace one agent ############

install_dynatrace_oneagent_chart() {

local chartName=$1
local TmpdDirectory=$2
local chartFileName=$3
local namespace=$4
local tier=$tierName
 az account set --subscription ${tier}01DevOpsAgents
    kv_uri=$AZ_KEYVAULT_URI
    echo "kv uri: $kv_uri"
    kv_uri=${kv_uri#https://}
    kv_name=${kv_uri%.vault.azure.net/}
    echo "kv name: $kv_name"
    dt_tenant=$(az keyvault secret show -n dt-tenant --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    echo "the tenant is: $dt_tenant"
    activegate_host=$(az keyvault secret show -n activegate-host --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    echo "the activegate is: $activegate_host"
    dynatrace_image_repo=$(az keyvault secret show -n dynatrace-image-repo --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    codemodules_image_tag=$(az keyvault secret show -n codemodules-image-tag --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    activegate_image_tag=$(az keyvault secret show -n activegate-image-tag --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    oneagent_image_tag=$(az keyvault secret show -n oneagent-image-tag --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    sleep 120
    helm upgrade --install $chartName $TmpdDirectory/$chartFileName --set "tenant=$dt_tenant,activeGate.env.host=$activegate_host,clusterName=$AksClusterName,codeModulesImage.image=${dynatrace_image_repo}/dynatrace/dynatrace-codemodules:${codemodules_image_tag},activeGate.image=${dynatrace_image_repo}/dynatrace/dynatrace-activegate:${activegate_image_tag},oneAgent.image=${dynatrace_image_repo}/dynatrace/dynatrace-oneagent:${oneagent_image_tag},automaticInjection=\"false\"" --namespace $namespace
}

##### dynatrace operator ##########
install_dynatrace_operator_chart() {

local chartName=$1
local TmpdDirectory=$2
local chartFileName=$3
local namespace=$4
local tier=$tierName
 az account set --subscription ${tier}01DevOpsAgents
    kv_uri=$AZ_KEYVAULT_URI
    echo "kv uri: $kv_uri"
    kv_uri=${kv_uri#https://}
    kv_name=${kv_uri%.vault.azure.net/}
    echo "kv name: $kv_name"
    activegate_token=$(az keyvault secret show -n activegate-token --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    dt_data_token=$(az keyvault secret show -n dt-data-token --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    dt_operator_token=$(az keyvault secret show -n dt-operator-token --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    dynatrace_image_repo=$(az keyvault secret show -n dynatrace-image-repo --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    operator_image_tag=$(az keyvault secret show -n operator-image-tag --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    helm upgrade --install $chartName $TmpdDirectory/$chartFileName --set "secret.data.apiToken=$dt_operator_token,secret.data.dataIngestToken=$dt_data_token,secret.data.installerToken=$activegate_token,imageRef.repository=${dynatrace_image_repo}/dynatrace/dynatrace-operator,imageRef.tag=${operator_image_tag}" --namespace $namespace
}
##### prisma ###########
install_prisma_chart() {
    local chartName=$1
    local TmpdDirectory=$2
    local chartFileName=$3
    local namespace=$4
    local tier=$tierName

    az account set --subscription ${tier}01DevOpsAgents
    kv_uri=$AZ_KEYVAULT_URI
    echo "kv uri: $kv_uri"
    kv_uri=${kv_uri#https://}
    kv_name=${kv_uri%.vault.azure.net/}
    echo "kv name: $kv_name"
    prisma_service_parameter=$(az keyvault secret show -n prisma-service-parameter --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    prisma_image_path=$(az keyvault secret show -n prisma-image-path --vault-name $kv_name --query "value" -o tsv) 2>/dev/null
    prisma_image_tag=$(az keyvault secret show -n prisma-image-tag --vault-name $kv_name --query "value" -o tsv) 2>/dev/null

    az account set --subscription ${tier}01ACR
    acr=$(az acr list -g rg-acr-${tier}-${location} --query "[0].name" -o tsv).azurecr.io
    echo "ACR: $acr"
    echo "Prisma image path: $prisma_image_path"
    echo "Prisma image tag: $prisma_image_tag"
    helm upgrade --install $chartName $TmpdDirectory/$chartFileName --set "image.registry=$acr,image.path=$prisma_image_path,image.tag=$prisma_image_tag,prisma.secret=$prisma_service_parameter" --namespace $namespace
}


echo "Getting credentials for AKS cluster $AksClusterName in resource group $ResourceGroupName"
az account set --subscription $SubscriptionId
az aks get-credentials --resource-group $ResourceGroupName --name $AksClusterName --overwrite-existing --admin





for chart in "${helmCharts[@]}" ; do
    eval "chart_details=(\"\${${chart}[@]}\")"
    namespace=${chart_details[0]}
    chartName=${chart_details[1]}
    artifact=${chart_details[2]}
    values=${chart_details[3]}
    chartPath="https://${artifactoryDomain}/artifactory/${artifactPath}/${artifact}"
    valuesPath="https://${artifactoryDomain}/artifactory/${artifactPath}/${values}"
    chartFileName=$(basename "$chartPath")
    valuesFileName=$(basename "$valuesPath")
    curl -o $TmpdDirectory/$chartFileName $chartPath --insecure
    if [ $? -ne 0 ]; then

        echo "Chart retrieval failed: $chartFileName from $chartPath"
        exit 1
    
    fi 
    ls -ltr $TmpdDirectory/$chartFileName

    if [[ -n $values ]]; then
        curl -o $TmpdDirectory/$valuesFileName $valuesPath --insecure
        if [ $? -ne 0 ]; then

            echo "Values retrieval failed: $valuesFileName from $valuesPath"
            exit 1

        fi
    fi
   # ls -ltr $TmpdDirectory/$valuesFileName
    is_cert_installed
    check_and_create_namespace "$namespace"

    echo "Installing Helm chart: $chartFileName with release name: $chartName in $namespace"
    if [ $chartName == "eso" ]; then
        
        helm upgrade --install $chartName $TmpdDirectory/$chartFileName -f $TmpdDirectory/$valuesFileName -f $BuildDirectory/azure-pipelines/scripts/eso_${tierName}.yaml --namespace $namespace

    elif [ $chartName == "nginx" ]; then
            
        get_ip_address_from_vnet
        echo "the assigned Load Balancer IP: $lbIp"
        helm upgrade --install $chartName $TmpdDirectory/$chartFileName -f $TmpdDirectory/$valuesFileName --set "controller.extraArgs.enable-ssl-passthrough=true","controller.service.loadBalancerIP=${lbIp}","controller.service.annotations.service\.beta\.kubernetes\.io/azure-load-balancer-internal=true","controller.service.annotations.service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path=/healthz" --namespace $namespace
    elif [ $chartName == "prisma" ]; then
        install_prisma_chart "$chartName" "$TmpdDirectory" "$chartFileName" "$namespace"
    


   elif [ $chartName == "dynatrace-operator" ]; then
       install_dynatrace_operator_chart "$chartName" "$TmpdDirectory" "$chartFileName" "$namespace"
    
   elif [ $chartName == "dynakube" ]; then
       install_dynatrace_oneagent_chart "$chartName" "$TmpdDirectory" "$chartFileName" "$namespace"
    fi
    if [ $? -ne 0 ]; then
        
        echo "Failed to install Helm chart: $chartFileName with release name: $chartName in $namepsace"
        exit 1
    fi

done
echo "All Helm charts have been successfully installed"

echo "enabling container log v2 schema"
kubectl apply -f $BuildDirectory/azure-pipelines/scripts/containerlogv2_configmap.yml --namespace kube-system --dry-run=client && kubectl apply -f $BuildDirectory/azure-pipelines/scripts/containerlogv2_configmap.yml --namespace kube-system
rm -fr $TmpdDirectory





