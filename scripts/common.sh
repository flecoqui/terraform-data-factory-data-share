#!/bin/bash
#
# executable
#

##############################################################################
# colors for formatting the ouput
##############################################################################
# shellcheck disable=SC2034
{
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color
}
##############################################################################
#- function used to check whether an error occured
##############################################################################
function checkError() {
    # shellcheck disable=SC2181
    if [ $? -ne 0 ]; then
        echo -e "${RED}\nAn error occured exiting from the current bash${NC}"
        exit 1
    fi
}

##############################################################################
#- print functions
##############################################################################
function printMessage(){
    echo -e "${GREEN}$1${NC}" 
}
function printWarning(){
    echo -e "${YELLOW}$1${NC}" 
}
function printError(){
    echo -e "${RED}$1${NC}" 
}
function printProgress(){
    echo -e "${BLUE}$1${NC}" 
}
##############################################################################
#- azure Login 
##############################################################################
function azLogin() {
    # Check if current process's user is logged on Azure
    # If no, then triggers az login
    azOk=true
    az account set -s "$AZURE_SUBSCRIPTION_ID" 2>/dev/null || azOk=false
    if [[ ${azOk} == false ]]; then
        echo -e "need to az login"
        az login --tenant "$AZURE_TENANT_ID"
    fi

    azOk=true
    az account set -s "$AZURE_SUBSCRIPTION_ID"   || azOk=false
    if [[ ${azOk} == false ]]; then
        echo -e "unknown error"
        exit 1
    fi
}
##############################################################################
#- check is Url is ready returning 200 and the expected response
##############################################################################
function checkUrl() {
    httpCode="404"
    apiUrl="$1"
    expectedResponse="$2"
    timeOut="$3"
    response=""
    count=0
    while [[ "$httpCode" != "200" ]] || [[ "$response" != "$expectedResponse" ]] && [[ $count -lt ${timeOut} ]]
    do
        SECONDS=0
        httpCode=$(curl -s -o /dev/null -L -w '%{http_code}' "$apiUrl") || true
        if [[ $httpCode == "200" ]]; then
            response=$(curl -s  "$apiUrl") || true
            response=${response//\"/}
        fi
        #echo "count=${count} code: ${httpCode} response: ${response} "
        sleep 10
        ((count=count+SECONDS))
    done
    if [ $httpCode == "200" ] && [ "${response}" == "${expectedResponse}" ]; then
        echo "true"
        return
    fi
    echo "false"
    return
}

##############################################################################
#- get localhost
##############################################################################
function get_local_host() {
CONTAINER_NAME="$1"
DEV_CONTAINER_ROOT="/dcworkspace"
DEV_CONTAINER_NETWORK=$(docker inspect $(hostname) | jq -r '.[0].HostConfig.NetworkMode')
FULL_PATH=$(cd $(dirname ""); pwd -P /$(basename ""))
    if [[ $FULL_PATH =~ ^$DEV_CONTAINER_ROOT.* ]] && [[ -n $DEV_CONTAINER_NETWORK ]]; then
        # running in dev container
        # connect devcontainer network to container
        if [[ $(docker container inspect "${CONTAINER_NAME}" | jq -r ".[].NetworkSettings.Networks.\"$DEV_CONTAINER_NETWORK\"") == null ]]; then 
            docker network connect ${DEV_CONTAINER_NETWORK} ${CONTAINER_NAME} 
        fi
        CONTAINER_IP=$(docker container inspect "${CONTAINER_NAME}" | jq -r ".[].NetworkSettings.Networks.\"$DEV_CONTAINER_NETWORK\".IPAddress")
        echo "$CONTAINER_IP"
    else
        echo "127.0.0.1"
    fi
}
##############################################################################
#- deployTerraformInfrastructure
#  deploy Azure Storage Account used to store Terraform states
#  arg 1: azure region
#  arg 2: prefix used for the names
#  arg 3: resource group name associated with the storage account
#  arg 4: storage account name
#  arg 5: container name
#  arg 6: terraform state name
##############################################################################
function deployTerraformInfrastructure(){
    subscription=$(az account show --output tsv --query id)
    tenant=$(az account show --output tsv --query tenantId)
    region="$1"
    prefix="$2"
    resourcegroup="$3"
    storage="$4"
    container="$5"
    tfstate="$6"

    if [[ -z $resourcegroup ]]; then
       resourcegroup="${prefix}rg"
    fi
    if [[ -z $storage ]]; then
        storage="${prefix}sto"
    fi    
    if [[ -z $container ]]; then
        container="${prefix}container"
    fi
    if [[ -z $tfstate ]]; then
        tfstate="${prefix}tfstate"
    fi
    
    # create resource group
    cmd="az group create  --subscription $subscription --location $region --name $resourcegroup --output none "
    printProgress "$cmd"
    eval "$cmd"

    # create storage account
    cmd="az storage account create --resource-group $resourcegroup --name $storage --sku Standard_LRS --encryption-services blob --output none "
    printProgress "$cmd"
    eval "$cmd"

    # Get Storage Account key
    storageAccountKey=$(az storage account keys list \
  -g "$resourcegroup" --account-name "$storage" \
  --query [0].value -o tsv)
    checkError
  
    # create storage container
    cmd="az storage container create --name $container --account-key $storageAccountKey  --account-name $storage --output none "
    printProgress "$cmd"
    eval "$cmd"
    checkError
}
##############################################################################
#- undeployTerraformInfrastructure
#  undeploy Azure Storage Account used to store Terraform states
#  arg 1: resource group name associated with the storage account
##############################################################################
function undeployTerraformInfrastructure(){
    subscription=$(az account show --output tsv --query id)
    resourcegroup="$1"

    if [[ -z $resourcegroup ]]; then
       resourcegroup="${prefix}rg"
    fi
    
    # create resource group
    cmd="az group delete  --subscription $subscription --name $resourcegroup -y --output none "
    printProgress "$cmd"
    eval "$cmd"
    checkError
}
