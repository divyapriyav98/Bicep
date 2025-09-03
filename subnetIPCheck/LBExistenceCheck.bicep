param location string
param UMIId string
param forceUpdateTag string = utcNow()
param ResourceGroupName string 
param subscriptionId string 
param loadBalancerName string 
// Use a deployment script for existence check since direct resource reference doesn't work for conditionals
resource loadBalancerExistenceCheck 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'loadBalancerExistenceCheck'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UMIId}': {}
    }
  }
  properties: {
    azCliVersion: '2.50.0'
    timeout: 'PT10M'
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnSuccess'
    forceUpdateTag: forceUpdateTag
    arguments: '--RESOURCE_GROUP "${ResourceGroupName }" --subscriptionId "${subscriptionId}" --LB_NAME "${loadBalancerName}"'
    // environmentVariables: [
    //   {
    //     name: 'RESOURCE_GROUP'
    //     value: vmssModuleSettings.loadbalancer.scope.?resourceGroupName ?? resourceGroup().name
    //   }
    //   {
    //     name: 'SUBSCRIPTION_ID'
    //     value: vmssModuleSettings.loadbalancer.scope.?subscriptionId ?? subscription().subscriptionId
    //   }
    //   {
    //     name: 'LB_NAME'
    //     value: loadBalancerName
    //   }
    // ]
    scriptContent: '''
      echo "Checking load balancer existence in resource group: $RESOURCE_GROUP"
      echo "Load balancer name: $LB_NAME"
     
      # Set the correct subscription context
      if [ -n "$SUBSCRIPTION_ID" ]; then
        az account set --subscription "$SUBSCRIPTION_ID"
      fi
     
      # Check if load balancer exists
      LB_EXISTS=$(az network lb show --resource-group "$RESOURCE_GROUP" --name "$LB_NAME" --query "name" --output tsv 2>/dev/null || echo "")
     
      if [ -n "$LB_EXISTS" ]; then
        echo " Load balancer exists: $LB_EXISTS"
        echo "Skipping load balancer deployment to prevent backend pool modification errors"
        echo "{\"loadBalancerExists\": true, \"shouldDeploy\": false}" > $AZ_SCRIPTS_OUTPUT_PATH
      else
        echo " Load balancer does not exist"
        echo "Will deploy new load balancer"
        echo "{\"loadBalancerExists\": false, \"shouldDeploy\": true}" > $AZ_SCRIPTS_OUTPUT_PATH
      fi
     
      echo " Load balancer existence check completed"
    '''
  
    outputs: {
      loadBalancerExists: '[loadBalancerExists]'
      shouldDeploy: '[shouldDeploy]'
    }
  }
}
// output deployLB bool = loadBalancerExistenceCheck.properties.outputs['shouldDeploy']
// output loadBalancerExists bool = loadBalancerExistenceCheck.properties.outputs['loadBalancerExists']


output loadBalancerExists bool = loadBalancerExistenceCheck.properties.outputs.loadBalancerExists
output deployLB bool = loadBalancerExistenceCheck.properties.outputs.shouldDeploy

// output loadBalancerExists bool = loadBalancerExistenceCheck.properties.outputs.result.loadBalancerExists
// output deployLB bool = loadBalancerExistenceCheck.properties.outputs.result.shouldDeploy
