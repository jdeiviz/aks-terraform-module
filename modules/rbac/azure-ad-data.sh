#!/bin/bash

set -e
set -u

NAME=$1
ENV=$2

CLUSTER_ADMINS_GROUP_NAME="${NAME}-aks-${ENV}-cluster-admin"

CLUSTER_ADMINS_GROUP_ID=$(az ad group list --display-name $CLUSTER_ADMINS_GROUP_NAME --query [].objectId -o tsv)
echo "{\"id\": \"${CLUSTER_ADMINS_GROUP_ID}\"}"
