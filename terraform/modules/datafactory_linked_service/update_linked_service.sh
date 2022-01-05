#!/usr/bin/env bash
set -euo pipefail
shopt -s extglob
echo "Create or remove Linked Service subscription_id: $1 action:$2 name: $3 datafactory: $4 resource group: $5 endpoint: $6"
subscription_id=$1
action=$2
name=$3
datafactory=$4
resource_group=$5
endpoint=$6
if [[ $# -eq 0 || -z $subscription_id || -z $action || -z $name || -z $datafactory ||  -z $resource_group || -z $endpoint ]]; then
    echo "Required parameters are missing"
    usage
    echo "Usage: ./update_linked_service.sh <action> <name> <datafactory> <resource_group> <endpoint>"
    echo "       ./update_linked_service.sh add <name> <datafactory> <resource_group> <endpoint>"
    echo "       ./update_linked_service.sh remove <name> <datafactory> <resource_group> <endpoint>"
    exit 1
fi
az config set extension.use_dynamic_install=yes_without_prompt
dfid=$(az datafactory linked-service show  --subscription "$subscription_id"  --factory-name "$datafactory" --name "$name" --resource-group "$resource_group" --output tsv 2> /dev/null ) || true
if [[ $action == "add" ]] ; then
    if [[ -z $dfid ]] ; then
        echo "Creating Linked Service $name"
        az datafactory linked-service create --subscription "$subscription_id"  --factory-name "$datafactory" --properties "{\"type\":\"AzureBlobStorage\",\"typeProperties\":{\"serviceEndpoint\":\"$endpoint\",\"accountKind\":\"StorageV2\"}}" --name "$name" --resource-group "$resource_group"
    else
        echo "Updating Linked Service $name"
        az datafactory linked-service update --subscription "$subscription_id"  --factory-name "$datafactory" --set properties.serviceEndpoint="$endpoint" --set properties.accountKind=StorageV2 --name "$name" --resource-group "$resource_group"
    fi
fi
if [[ $action == "remove" ]] ; then
    if [[ -n $dfid ]] ; then
        echo "Removing Linked Service $name"
        az datafactory linked-service delete --subscription "$subscription_id"  --yes --factory-name "$datafactory" --name "$name" --resource-group "$resource_group"
    fi
fi
