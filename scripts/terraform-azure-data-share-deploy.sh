#!/bin/bash
#
# executable
#

set -e
# Read variables in configuration file
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")/../"
    pwd -P
)
SCRIPTS_DIRECTORY=`dirname $0`
source "$SCRIPTS_DIRECTORY"/common.sh

# webapp prefix 
export AZURE_PREFIX="testterds"

env_path=$1
if [[ -z $env_path ]]; then
    env_path="$(dirname "${BASH_SOURCE[0]}")/../configuration/.default.env"
fi

printMessage "Starting test with Terraform using the configuration in this file ${env_path}"

if [[ $env_path ]]; then
    if [ ! -f "$env_path" ]; then
        printError "$env_path does not exist."
        exit 1
    fi
    set -o allexport
    source "$env_path"
    set +o allexport
else
    printWarning "No env. file specified. Using environment variables."
fi

# Check Azure connection
printMessage "Check Azure connection for subscription: '$AZURE_SUBSCRIPTION_ID'"
azLogin
checkError

# Deploy Terraform Infrastructure
printMessage "Deploy Terraform infrastructure subscription: '$AZURE_SUBSCRIPTION_ID' region: '$AZURE_REGION' prefix: '$AZURE_PREFIX' "
deployTerraformInfrastructure $AZURE_REGION $AZURE_PREFIX $TERRAFORM_RESOURCE_GROUP $TERRAFORM_STORAGE_ACCOUNT $TERRAFORM_STORAGE_CONTAINER "$AZURE_PREFIX-$TERRAFORM_NAME"

pushd "$(dirname "${BASH_SOURCE[0]}")/../terraform/datashare" > /dev/null

cmd="terraform init \
  -backend-config="storage_account_name=$storage" \
  -backend-config="container_name=$container" \
  -backend-config="access_key=$storageAccountKey" \
  -backend-config="key=$tfstate""
printProgress "$cmd"
eval "$cmd"
checkError

cmd="terraform apply -state="$tfstate" -auto-approve"
printProgress "$cmd"
eval "$cmd"
checkError

datashare_resource_group_name="$(terraform output --raw datashare_resource_group_name)"
datashare_name="$(terraform output --raw datashare_name)"
datashare_storage_name="$(terraform output --raw  datashare_storage_name)"
datashare_storage_container_provider_name="$(terraform output --raw  datashare_storage_container_provider_name)"
datashare_storage_container_consumer_name="$(terraform output --raw  datashare_storage_container_consumer_name)"

printProgress "Data Share Resource Group Name '${datashare_resource_group_name}' created"
printProgress "Data Share Resource Group Name '${datashare_resource_group_name}' created"
printProgress "Data Share Account '${datashare_name}' created"
printProgress "Storage Account '${datashare_storage_name}' created"
printProgress "Storage Container Provider '${datashare_storage_container_provider_name}' created"
printProgress "Storage Container Consumer '${datashare_storage_container_consumer_name}' created"

# Testing Data Share and Storage deployment using azure cli
cmd="az config set extension.use_dynamic_install=yes_without_prompt  > /dev/null 2>&1"
printProgress "$cmd"
eval "$cmd"
checkError

cmd="az provider register --name \"Microsoft.DataShare\"  > /dev/null 2>&1"
printProgress "$cmd"
eval "$cmd"
checkError

name=$(az datashare account show --name ${datashare_name} -g ${datashare_resource_group_name} --output json | jq -r .name) || true
if [[ "${name}" == "${datashare_name}" ]]; then
    printProgress "Data Share Account successfully tested: ${datashare_name}"
else
    printError "Error while testing Data Share Account : ${datashare_name}"
    exit 1
fi

name=$(az storage account show --name ${datashare_storage_name} -g ${datashare_resource_group_name} --output json | jq -r .name) || true
if [[ "${name}" == "${datashare_storage_name}" ]]; then
    printProgress "Data Share Storage Account successfully tested: ${datashare_storage_name}"
else
    printError "Error while testing Data Share Storage Account : ${datashare_storage_name}"
    exit 1
fi

storageAccountKey=$(az storage account keys list -g "${datashare_resource_group_name}" --account-name "${datashare_storage_name}" --query [0].value -o tsv) || true
checkError

name=$(az storage container show --name ${datashare_storage_container_provider_name} --account-name ${datashare_storage_name} --account-key $storageAccountKey --output json | jq -r .name) || true
if [[ "${name}" == "${datashare_storage_container_provider_name}" ]]; then
    printProgress "Data Share Storage Container successfully tested: ${datashare_storage_container_provider_name}"
else
    printError "Error while testing Data Share Storage Container : ${datashare_storage_container_provider_name}"
    exit 1
fi

name=$(az storage container show --name ${datashare_storage_container_consumer_name} --account-name ${datashare_storage_name} --account-key $storageAccountKey --output json | jq -r .name) || true
if [[ "${name}" == "${datashare_storage_container_consumer_name}" ]]; then
    printProgress "Data Share Storage Container successfully tested: ${datashare_storage_container_consumer_name}"
else
    printError "Error while testing Data Share Storage Container : ${datashare_storage_container_consumer_name}"
    exit 1
fi

# undeploying the data share resources
cmd="terraform destroy -state="$tfstate" -auto-approve"
printProgress "$cmd"
eval "$cmd"
checkError

# removing cache for subsequent calls
cmd="rm -rf .terraform*"
printProgress "$cmd"
eval "$cmd"
checkError

popd > /dev/null

# Undeploy Terraform Infrastructure
undeployTerraformInfrastructure $resourcegroup

printMessage "Test Succesful"
