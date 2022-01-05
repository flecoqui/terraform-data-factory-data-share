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
export AZURE_PREFIX="testterdf"

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

pushd "$(dirname "${BASH_SOURCE[0]}")/../terraform/datafactory" > /dev/null

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

datafactory_resource_group_name="$(terraform output --raw datafactory_resource_group_name)"
datafactory_name="$(terraform output --raw datafactory_name)"
datafactory_storage_name="$(terraform output --raw  datafactory_storage_name)"
datafactory_storage_container_input_name="$(terraform output --raw  datafactory_storage_container_input_name)"
datafactory_storage_container_output_name="$(terraform output --raw  datafactory_storage_container_output_name)"
input_linked_service_name="$(terraform output --raw  input_linked_service_name)"
output_linked_service_name="$(terraform output --raw  output_linked_service_name)"

printProgress "Data Factory Resource Group Name '${datafactory_resource_group_name}' created"
printProgress "Data Factory Account '${datafactory_name}' created"
printProgress "Storage Account '${datafactory_storage_name}' created"
printProgress "Storage Container Input '${datafactory_storage_container_input_name}' created"
printProgress "Storage Container Output '${datafactory_storage_container_output_name}' created"
printProgress "Data Factory Linked Service Input Name '${input_linked_service_name}' created"
printProgress "Data Factory Linked Service Output Name '${output_linked_service_name}' created"


# Testing Data Factory and Storage deployment using azure cli
cmd="az config set extension.use_dynamic_install=yes_without_prompt  > /dev/null 2>&1"
printProgress "$cmd"
eval "$cmd"
checkError

name=$(az datafactory show --name ${datafactory_name} -g ${datafactory_resource_group_name} --output json | jq -r .name) || true
if [[ "${name}" == "${datafactory_name}" ]]; then
    printProgress "Data Factory successfully tested: ${datafactory_name}"
else
    printError "Error while testing Data Factory Account : ${datafactory_name}"
    exit 1
fi

name=$(az storage account show --name ${datafactory_storage_name} -g ${datafactory_resource_group_name} --output json | jq -r .name) || true
if [[ "${name}" == "${datafactory_storage_name}" ]]; then
    printProgress "Data Factory Storage Account successfully tested: ${datafactory_storage_name}"
else
    printError "Error while testing Data Factory Storage Account : ${datafactory_storage_name}"
    exit 1
fi

storageAccountKey=$(az storage account keys list -g "${datafactory_resource_group_name}" --account-name "${datafactory_storage_name}" --query [0].value -o tsv) || true
checkError

name=$(az storage container show --name ${datafactory_storage_container_input_name} --account-name ${datafactory_storage_name} --account-key $storageAccountKey --output json | jq -r .name) || true
if [[ "${name}" == "${datafactory_storage_container_input_name}" ]]; then
    printProgress "Data Factory Storage Container successfully tested: ${datafactory_storage_container_input_name}"
else
    printError "Error while testing Data Factory Storage Container : ${datafactory_storage_container_input_name}"
    exit 1
fi

name=$(az storage container show --name ${datafactory_storage_container_output_name} --account-name ${datafactory_storage_name} --account-key $storageAccountKey --output json | jq -r .name) || true
if [[ "${name}" == "${datafactory_storage_container_output_name}" ]]; then
    printProgress "Data Factory Storage Container successfully tested: ${datafactory_storage_container_output_name}"
else
    printError "Error while testing Data Factory Storage Container : ${datafactory_storage_container_output_name}"
    exit 1
fi

# undeploying the data factory resources
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

echo "done."