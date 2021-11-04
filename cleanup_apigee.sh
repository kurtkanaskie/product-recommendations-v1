#! /bin/bash

# Set environment variables, ORG === GCP Project
export TOKEN=$(gcloud auth print-access-token)
export ORG=ngsaas-5g-kurt
export ENV=test-1
export ENVGROUP_HOST=napi-test.kurtkanaskie.net

echo; echo Using Apigee X project "$ORG", environment "$ENV" and envGroup hostname "$ENVGROUP_HOST" ========================
read -p "OK to proceed (Y/n)? " i
if [ "$i" != "Y" ]
then
  echo aborted
  exit 1
fi
echo Proceeding...

# Set project for gcloud
gcloud config set project $ORG

## Delete Service Account
echo Deleting Service Account ========================
export SA=$(gcloud iam service-accounts list | grep datareader | cut -d" " -f12)
gcloud iam service-accounts delete $SA --quiet
echo Deleted SA $SA


# Delete App, Developer and API Product
echo Deleting API Product, Developer and App ========================
apigeecli -t $TOKEN -o $ORG apps delete --id 'demo@any.com' -n "Electronics Store $ENV"
apigeecli -t $TOKEN -o $ORG developers delete --email 'demo@any.com'
apigeecli -t $TOKEN -o $ORG products delete --name product-recommendations-v1-$ENV

# Undeploy and delete proxy
# Due to a bug with "-1" revision, you can't delete the proxy if its deployed, need to undeploy the deployed revision first.
echo Undeploying and Deleting proxy ========================
REV=$(apigeecli -t $TOKEN --org $ORG apis listdeploy --name product-recommendations-v1 | jq '.deployments[0].revision | tonumber')
apigeecli -t $TOKEN --org $ORG apis undeploy --env $ENV --name product-recommendations-v1 --rev $REV
apigeecli -t $TOKEN --org $ORG apis delete --name product-recommendations-v1 --rev 1
