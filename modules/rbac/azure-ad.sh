#!/bin/bash

set -e
set -u

NAME=$1
ENV=$2

AKS_APP_NAME="${NAME}-aks-${ENV}-ad-app"
AKS_APP_SECRET=$3

# create aks service principal

AKS_APP_ID=$(az ad app list --display-name $AKS_APP_NAME --query [].appId -o tsv)
if [[ -z "${AKS_APP_ID}" ]]; then
  echo "Creating aks application and service principal..."
  az ad sp create-for-rbac --name $AKS_APP_NAME --password "${AKS_APP_SECRET}" --years 5 --skip-assignment
  AKS_APP_ID=$(az ad app list --display-name $AKS_APP_NAME --query [].appId -o tsv)
fi

RBAC_SERVER_APP_NAME="${NAME}-aks-${ENV}-server-ad-app"
RBAC_SERVER_APP_URL="https://${NAME}-aks-${ENV}-server"
RBAC_SERVER_APP_SECRET=$4

RBAC_SERVER_APP_ID=$(az ad app list --display-name $RBAC_SERVER_APP_NAME --query [].appId -o tsv)
if [[ -z "${RBAC_SERVER_APP_ID}" ]]; then
  # generate manifest for server application
  cat > ./manifest-server.json << EOF
  [
    {
      "resourceAppId": "00000003-0000-0000-c000-000000000000",
      "resourceAccess": [
        {
          "id": "7ab1d382-f21e-4acd-a863-ba3e13f7da61",
          "type": "Role"
        },
        {
          "id": "06da0dbc-49e2-44d2-8312-53f166ab848a",
          "type": "Scope"
        },
        {
          "id": "e1fe6dd8-ba31-4d61-89e7-88639da4683d",
          "type": "Scope"
        }
      ]
    },
    {
      "resourceAppId": "00000002-0000-0000-c000-000000000000",
      "resourceAccess": [
        {
          "id": "311a71cc-e848-46a1-bdf8-97ff7156d8e6",
          "type": "Scope"
        }
      ]
    }
  ]
EOF

  # create the Azure Active Directory server application
  echo "Creating server application..."
  az ad app create --display-name ${RBAC_SERVER_APP_NAME} \
      --password "${RBAC_SERVER_APP_SECRET}" \
      --end-date "2024-01-01" \
      --identifier-uris "${RBAC_SERVER_APP_URL}" \
      --reply-urls "${RBAC_SERVER_APP_URL}" \
      --homepage "${RBAC_SERVER_APP_URL}" \
      --required-resource-accesses @manifest-server.json

  RBAC_SERVER_APP_ID=$(az ad app list --display-name $RBAC_SERVER_APP_NAME --query [].appId -o tsv)
  
  # update the application
  az ad app update --id ${RBAC_SERVER_APP_ID} --set groupMembershipClaims=All

  # create service principal for the server application
  echo "Creating service principal for server application..."
  az ad sp create --id ${RBAC_SERVER_APP_ID}
  # grant permissions to server application
  echo "Granting permissions to the server application..."
  RBAC_SERVER_APP_RESOURCES_API_IDS=$(az ad app permission list --id $RBAC_SERVER_APP_ID --query [].resourceAppId --out tsv | xargs echo)
  for RESOURCE_API_ID in $RBAC_SERVER_APP_RESOURCES_API_IDS;
  do
    if [ "$RESOURCE_API_ID" == "00000002-0000-0000-c000-000000000000" ]
    then
      az ad app permission grant --api $RESOURCE_API_ID --id $RBAC_SERVER_APP_ID --scope "User.Read"
    elif [ "$RESOURCE_API_ID" == "00000003-0000-0000-c000-000000000000" ]
    then
      az ad app permission grant --api $RESOURCE_API_ID --id $RBAC_SERVER_APP_ID --scope "Directory.Read.All"
    else
      az ad app permission grant --api $RESOURCE_API_ID --id $RBAC_SERVER_APP_ID --scope "user_impersonation"
    fi
  done

  # remove manifest-server.json
  rm ./manifest-server.json
fi

# load environment variables
RBAC_CLIENT_APP_NAME="${NAME}-aks-${ENV}-client-ad-app"
RBAC_CLIENT_APP_URL="https://${NAME}-aks-${ENV}-client"

RBAC_CLIENT_APP_ID=$(az ad app list --display-name ${RBAC_CLIENT_APP_NAME} --query [].appId -o tsv)
RBAC_SERVER_APP_OAUTH2PERMISSIONS_ID=$(az ad app show --id ${RBAC_SERVER_APP_ID} --query oauth2Permissions[0].id -o tsv)
if [[ -z "${RBAC_CLIENT_APP_ID}" ]]; then
  # generate manifest for client application
  cat > ./manifest-client.json << EOF
  [
      {
        "resourceAppId": "${RBAC_SERVER_APP_ID}",
        "resourceAccess": [
          {
            "id": "${RBAC_SERVER_APP_OAUTH2PERMISSIONS_ID}",
            "type": "Scope"
          }
        ]
      }
  ]
EOF

  # create client application
  echo "Creating client application..."
  az ad app create --display-name ${RBAC_CLIENT_APP_NAME} \
      --native-app \
      --reply-urls "${RBAC_CLIENT_APP_URL}" \
      --homepage "${RBAC_CLIENT_APP_URL}" \
      --required-resource-accesses @manifest-client.json

  RBAC_CLIENT_APP_ID=$(az ad app list --display-name ${RBAC_CLIENT_APP_NAME} --query [].appId -o tsv)

  # create service principal for the client application
  echo "Creating service principal for client application..."
  az ad sp create --id ${RBAC_CLIENT_APP_ID}

  # remove manifest-client.json
  rm ./manifest-client.json

  # grant permissions to server application
  echo "Granting permissions to the client application..."
  RBAC_CLIENT_APP_RESOURCES_API_IDS=$(az ad app permission list --id $RBAC_CLIENT_APP_ID --query [].resourceAppId --out tsv | xargs echo)
  for RESOURCE_API_ID in $RBAC_CLIENT_APP_RESOURCES_API_IDS;
  do
    az ad app permission grant --api $RESOURCE_API_ID --id $RBAC_CLIENT_APP_ID
  done
fi

ACR_NAME="${NAME}acr${ENV}"
PUSH_ACR_APP_NAME="${NAME}-acr-${ENV}-push-ad-app"
PUSH_ACR_APP_SECRET=$5

# create push acr service principal
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)
PUSH_ACR_APP_ID=$(az ad app list --display-name $PUSH_ACR_APP_NAME --query [].appId -o tsv)
if [[ -z "${PUSH_ACR_APP_ID}" ]]; then
  echo "Creating push acr application and service principal..."
  az ad sp create-for-rbac --name $PUSH_ACR_APP_NAME --password "${PUSH_ACR_APP_SECRET}" --scopes $ACR_REGISTRY_ID --role acrpush --years 5
  PUSH_ACR_APP_ID=$(az ad app list --display-name $PUSH_ACR_APP_NAME --query [].appId -o tsv)
fi

# create cluster admins group
CLUSTER_ADMINS_GROUP_NAME="${NAME}-aks-${ENV}-cluster-admin"

CLUSTER_ADMINS_GROUP_ID=$(az ad group list --display-name $CLUSTER_ADMINS_GROUP_NAME --query [].objectId -o tsv)
if [[ -z "${CLUSTER_ADMINS_GROUP_ID}" ]]; then
  echo "Creating cluster admins group"
  az ad group create --display-name $CLUSTER_ADMINS_GROUP_NAME --mail-nickname $CLUSTER_ADMINS_GROUP_NAME
  CLUSTER_ADMINS_GROUP_ID=$(az ad group list --display-name $CLUSTER_ADMINS_GROUP_NAME --query [].objectId -o tsv)
fi

echo "The Azure Active Directory applications have been created. You need to ask an Azure AD Administrator to go the Azure portal an click the 'Grant permissions' button for these apps."
