mkdir /application
cd /application
function bootstrap_oneagent() {
  # create a oneagent de-registration script using VMSS terminate notifications that will be added to the crontab during bootstrap_oneagent
  cat >/opt/dynatrace/oneagent/agent/deregister_oneagent.sh <<EOF
  #!/bin/bash

  #Extract Instance Name from Metadata API
  vm_name=$(curl --silent -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-11-01" | python -c 'import sys, json; print (json.load(sys.stdin)["compute"]["name"])')

  #Check if Instance is scheduled for deletion from Metadata API
  check=$(curl --silent -H Metadata:true 'http://169.254.169.254/metadata/scheduledevents?api-version=2020-07-01' | python -c "import sys, json; obj=json.load(sys.stdin); print[q.get('EventType') for q in obj['Events'] if '$vm_name' in q.get('Resources') and 'Terminate' in q.get('EventType')];")

  #If Instance is scheduled for deletion ($check is not null), uninstall dynatrace or execute any other cleanup scripts
  if [[ "$check" != "[]" ]]; then
      echo "Termination Event received, Uninstalling Dynatrace OneAgent"
      bash /opt/dynatrace/oneagent/agent/uninstall.sh
      event_id=$(curl --silent -H Metadata:true 'http://169.254.169.254/metadata/scheduledevents?api-version=2020-07-01' | python -c "import sys, json; obj=json.load(sys.stdin); print[q.get('EventId') for q in obj['Events'] if '$vm_name' in q.get('Resources') and 'Terminate' in q.get('EventType')];" | sed -e "s/^\[u'//" -e "s/']$//")
      #Post to Metadata API after cleanup to avoid timeout
      curl -d '{"StartRequests":[{"EventId": "'$event_id'"}]}' -H Metadata:true 'http://169.254.169.254/metadata/scheduledevents?api-version=2020-07-01' 
  fi
EOF
  chmod +x /opt/dynatrace/oneagent/agent/deregister_oneagent.sh
  
  ACTIVEGATE_AGENT=oneagent.sh
  ACTIVEGATE_HOST=dynatrace.stage.logging.nonp.eastus.az.mastercard.int
  ACTIVEGATE_COMMUNICATION_URL="https://$ACTIVEGATE_HOST:443/communication"
  ACTIVEGATE_ENV=zak33936
  ACTIVEGATE_API_TOKEN=XCCc4sfeQnW2ptC9hpWLi
  ACTIVEGATE_NETWORK_ZONE=azure.eastus
  ACTIVEGATE_AGENT_HOST_GROUP=nonp01BuildersCloudSonarHA_jenkinsha-builderscloudsonarha_BuildersCloudSonarHA_stage

  echo "Testing connectivity to $ACTIVEGATE_HOST"
  if ! timeout 5 curl -k $ACTIVEGATE_COMMUNICATION_URL; then
      echo "ERROR: Could not reach https://$ACTIVEGATE_HOST, skipping oneAgent bootstrap"
  elif [[ ! -f $ACTIVEGATE_AGENT ]]; then
      echo "ERROR: $ACTIVEGATE_AGENT expected to have been downloaded from artifact storage but it is not found"
  else
      echo "Bootstrapping Dynatrace oneAgent from ActiveGate host @ $ACTIVEGATE_HOST"
      chmod +x $ACTIVEGATE_AGENT
      if SERVER=$ACTIVEGATE_COMMUNICATION_URL ./$ACTIVEGATE_AGENT --set-server=https://$ACTIVEGATE_HOST:443 --set-network-zone=$ACTIVEGATE_NETWORK_ZONE --set-host-group=$ACTIVEGATE_AGENT_HOST_GROUP; then
          (crontab -u root -l; crontab -u root -l | egrep -q "^\* \* \* \* \* /opt/dynatrace/oneagent/agent/deregister_oneagent.sh$" || echo "* * * * * /opt/dynatrace/oneagent/agent/deregister_oneagent.sh") | crontab -u root -
          echo "Dynatrace oneAgent bootstrap complete" && return 0
      fi
  fi
  echo "ERROR: Dynatrace oneAgent bootstrapping failed" && return 1
}

function bootstrap_prisma() {
  PRISMA_CLOUD_HOST="us-west1.cloud.twistlock.com"
  PRISMA_CLOUD_ENV="us-3-159242058"
  PRISMA_CLOUD_USERNAME_KV_SECRET="prisma-client-id"
  PRISMA_CLOUD_SECRET_KV_SECRET="prisma-client-secret"

  set +x
  source /etc/profile.d/vmssvars.sh
  USERNAME=$(vault_secret $PRISMA_CLOUD_USERNAME_KV_SECRET)
  PASSWORD=$(vault_secret $PRISMA_CLOUD_SECRET_KV_SECRET)

  fail_msg="ERROR: Prisma Cloud Defender agent bootstrapping failed"

  if [[ -z "$USERNAME" ]] || [[ -z "$PASSWORD" ]]; then
      echo "ERROR: Could not obtain $PRISMA_CLOUD_USERNAME_KV_SECRET or $PRISMA_CLOUD_SECRET_KV_SECRET in application keyvault"
      echo fail_msg && set -x && return 1
  fi

  echo "Bootstrapping Prisma Cloud Defender agent from $PRISMA_CLOUD_HOST ($PRISMA_CLOUD_ENV) with client id $USERNAME"
  set -o pipefail

  curl --fail -H "Content-Type: application/json" \
      -d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}" \
      https://$PRISMA_CLOUD_HOST/$PRISMA_CLOUD_ENV/api/v1/authenticate |
      python3 -c "import sys; import json; body = json.loads(sys.stdin.readline()); print(body['token'])" |
      xargs echo -n > prisma_defender_token
  if [[ $? != 0 ]]; then
      echo "ERROR: Could not obtain deployment token from $PRISMA_CLOUD_HOST/$PRISMA_CLOUD_ENV for $USERNAME"
      echo $fail_msg && set -x && return 1
  fi
  set -x

  token="$(cat prisma_defender_token)"
  curl --fail -X POST -o defender.sh --header "Authorization: Bearer $token" "https://$PRISMA_CLOUD_HOST/$PRISMA_CLOUD_ENV/api/v1/scripts/defender.sh"
  if [[ $? != 0 ]]; then
      echo "ERROR: Could not obtain Prisma defender installation script from $PRISMA_CLOUD_HOST/$PRISMA_CLOUD_ENV" 
      echo $fail_msg && set -x && return 1
  fi

  chmod +x defender.sh
  ./defender.sh -c "$PRISMA_CLOUD_HOST" -d "none" --install-host
  if [[ $? != 0 ]]; then
      echo "ERROR: Prisma defender installation failed" 
      echo $fail_msg && set -x && return 1
  fi
  echo "Prisma Cloud Defender agent bootstrap complete" && set -x && return 0
}

# Configure environment variables
echo "export AZ_REGION=eastus" >> /etc/profile.d/vmssvars.sh
echo "export AZ_SERVICE_TIER=nonp" >> /etc/profile.d/vmssvars.sh
echo "export AZ_SERVICE_NAME=jenkins-hahs-nginx" >> /etc/profile.d/vmssvars.sh
echo "export AZ_APPLICATION_NAME=BuildersCloudSonarHA" >> /etc/profile.d/vmssvars.sh
echo "export AZ_ENVIRONMENT=stage" >> /etc/profile.d/vmssvars.sh
echo "export AZ_DNSZONE=eastus.az.mastercard.local" >> /etc/profile.d/vmssvars.sh
echo "export AZ_SUBSCRIPTION=nonp01BuildersCloudSonarHA" >> /etc/profile.d/vmssvars.sh
echo "export AZ_KEYVAULT_URI=https://appkv-ehua-azts2mxqujjay.vault.azure.net/" >> /etc/profile.d/vmssvars.sh
echo "export AZ_MSI_ID=/subscriptions/2f17563f-fad8-432f-bdc4-73bb8c4def67/resourceGroups/persistent-ehua6u6gl-avms-dev-nonp-eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/vmss-ehua6u6gl-dev-nonp-eastus-msi" >> /etc/profile.d/vmssvars.sh
echo "export AZ_MSI_CLIENT_ID=2b6462cd-0dce-4bb0-b3a1-14ed9f0bdbab" >> /etc/profile.d/vmssvars.sh
echo "export AZ_GITSHA_SHORT=65fe57ets2507302329" >> /etc/profile.d/vmssvars.sh
echo "export AZ_CERT_NAME=jenkinsha.dev.builderscloudsonarha.nonp.eastus" >> /etc/profile.d/vmssvars.sh
echo "export AZ_CERT_KEY_PASSPHRASE=jenkinsha-dev-builderscloudsonarha-nonp-eastus-pass" >> /etc/profile.d/vmssvars.sh
echo "export AZ_VMSS_NAME=vmss-ehua6u6gl-dev-nonp-eastus-0" >> /etc/profile.d/vmssvars.sh
echo "export AZ_VMSS_RG_NAME=persistent-ehua6u6gl-avms-dev-nonp-eastus" >> /etc/profile.d/vmssvars.sh
echo "export AZ_SUBSCRIPTION_ID=2f17563f-fad8-432f-bdc4-73bb8c4def67" >> /etc/profile.d/vmssvars.sh
echo "export AZ_STORAGE_ACCOUNT=stehuaazts2mxqujjay" >> /etc/profile.d/vmssvars.sh
echo "export JENKINS_DOMAIN=jenkinsha.dev.builderscloudsonarha.nonp.eastus.az.mastercard.int" >> /etc/profile.d/vmssvars.sh
echo "export JENKINS_URL=https://jenkinsha.dev.builderscloudsonarha.nonp.eastus.az.mastercard.int" >> /etc/profile.d/vmssvars.sh

vault_secret_function="function vault_secret() {
       token_response=\$(curl --silent 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true -s);
       access_token=\$(echo \$token_response | python -c 'import sys, json; print (json.load(sys.stdin)[\"access_token\"])');
       secret_response=\$(curl --silent \$AZ_KEYVAULT_URI/secrets/\$1?api-version=2016-10-01 -H \"Authorization: Bearer \$access_token\");
       secret_value=\$(echo \$secret_response | python -c 'import sys, json; print (json.load(sys.stdin)[\"value\"])');
       echo \$secret_value;
     }"

echo $vault_secret_function >> /etc/profile.d/vmssvars.sh
echo "export -f vault_secret" >> /etc/profile.d/vmssvars.sh

source /etc/profile.d/vmssvars.sh


# ensure java specific env vars are set if applicable
if [[ -e /etc/profile.d/java.sh ]]; then
  source /etc/profile.d/java.sh
fi

# auth to the local azure services
response=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fstorage.azure.com%2F' -H Metadata:true -s)
access_token=$(echo $response | python -c 'import sys, json; print (json.load(sys.stdin)["access_token"])')

# pull down service artifacts
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O MC-RHEL8.repo \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/MC-RHEL8.repo"
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O manage_dependencies.sh \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/manage_dependencies.sh"
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O nginx.sh \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/nginx.sh"
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O syslog.sh \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/syslog.sh"
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O startup_jenkins_api_server.sh \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/startup_jenkins_api_server.sh"
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O jenkins-api-server-1.0.0-20250514.102040-5.jar \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/jenkins-api-server-1.0.0-20250514.102040-5.jar"
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O jenkins-hahs-nginx.sh \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/jenkins-hahs-nginx.sh"
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O oneagent.sh \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/oneagent.sh"
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O jenkinsha.dev.builderscloudsonarha.nonp.eastus.crt \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/jenkinsha.dev.builderscloudsonarha.nonp.eastus.crt"
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O jenkinsha.dev.builderscloudsonarha.nonp.eastus.key \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/jenkinsha.dev.builderscloudsonarha.nonp.eastus.key"
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O jenkinsha.dev.builderscloudsonarha.nonp.eastus.jks \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/jenkinsha.dev.builderscloudsonarha.nonp.eastus.jks"
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O jenkinsha.dev.builderscloudsonarha.nonp.eastus.p12 \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/jenkinsha.dev.builderscloudsonarha.nonp.eastus.p12"

# pull down the service setup script
wget \
  --header="x-ms-version: 2019-02-02" \
  --header="Authorization: Bearer $access_token" \
  -O service_config.sh \
  -q "https://stehuaazts2mxqujjay.blob.core.windows.net/vmsscontainer/jenkins-hahs-nginx.sh"

ls -al

bootstrap_oneagent
bootstrap_prisma &
echo "bootstrap of oneagent + prisma complete"



# run the setup script and grab the output
if bash service_config.sh 1>output 2>&1; then
  echo 'Application bootstrap outputs:'
  cat output
  echo 'Service installation successful';
else
  echo 'Service bootstrap error outputs:'
  cat output
  echo 'Service installation unsuccessful';
fi





# Opening up backend port on host-based firewall for LB health probe and traffic to go through

systemctl unmask firewalld
systemctl start firewalld
firewall-cmd --state
firewall-cmd --add-port=443/tcp
firewall-cmd --query-port=443/tcp

