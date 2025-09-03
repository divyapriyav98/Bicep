#!/bin/bash

################################################
# Environment parameters from script arguments #
################################################
BuildDirectory=$1
location=$2
appName=$3
SubscriptionId=$4
appEnv=$5
hostEnv=$6
tierName=$7
shortTierName=$8

export PATH=$PATH:/usr/local/bin
checkNginx=(nginx nginx)
checkEso=(external-secrets eso)
checkPrisma=(twistlock prisma)
checkOperator=(dynatrace dynatrace-operator)
checkOneagent=(dynatrace dynakube)
validateInstalls=(
        checkNginx
        checkEso
        checkPrisma
      #  checkOperator
      #  checkOneagent
)
#ResourceGroupName="persistent-${appName}-ta-sn-${tierName}-${envName}-eu"
ResourceGroupName="persistent-aks-ta-${appEnv}-${hostEnv}-${location}"
AksClusterName="aks-${appEnv}-${hostEnv}-${location}"
sleep 300
az account set --subscription $SubscriptionId
az aks get-credentials --resource-group $ResourceGroupName --name $AksClusterName --overwrite-existing --admin

for validateInstall in "${validateInstalls[@]}" ; do
    eval "validate=(\"\${${validateInstall}[@]}\")"
    namespace=${validate[0]}
    release=${validate[1]}
    
    releaseStatus=$(helm list --namespace $namespace --filter "^$release$" -o json | jq -r '.[0].status')
    if [ "$releaseStatus" != "deployed" ]; then
        echo "$release not deployed. Status: $releaseStatus"
        exit 1

    fi
    echo " validating $release pods"




    allPodsRunning=true

    for pod in $(kubectl get pods --namespace nginx --no-headers -o custom-columns=":metadata.name"); do

        podStatus=$(kubectl get pod $pod --namespace nginx --no-headers -o custom-columns=":status.phase")
        if [ "$podStatus" != "Running" ]; then
            echo "Pod $pod is not running. Status: $podStatus"
            echo "Describing pod"
            kubectl describe pod $pod --namespace nginx
            allPodsRunning=false
        fi

    done

    if [ "$allPodsRunning" = false ]; then
        echo "pod validation - not successful"
        exit 1

    fi
done
echo "Helm install validation - Successful"
