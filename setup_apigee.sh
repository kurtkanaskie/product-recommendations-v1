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

# Set project for gcloud commands 
gcloud config set project $ORG

## Create Service Account
echo Creating Service Account ========================
gcloud iam service-accounts create datareader --display-name="Data reader for BQ and Spanner Demo"
echo Sleeping for 5 seconds to ensure SA is created.
sleep 5
export SA=$(gcloud iam service-accounts list | grep datareader | cut -d" " -f12)
# e.g. datareader@ngsaas-5g-kurt.iam.gserviceaccount.com
echo Created SA $SA

# Create and deploy proxy
echo Creating proxy ========================
apigeecli -t $TOKEN --org $ORG apis create --name product-recommendations-v1 --proxy ./product-recommendations-v1.zip
echo Deploying proxy ========================
apigeecli -t $TOKEN --org $ORG apis deploy-wait --env test-1 --name product-recommendations-v1 --rev 1 --sa $SA

# Create API Product, Developer and App
echo Creating API Product, Developer and App ========================
apigeecli -t $TOKEN -o $ORG products create --name product-recommendations-v1-$ENV \
	--envs $ENV --proxies product-recommendations-v1 --approval auto --opgrp operations.json \
	--displayname product-recommendations-v1-$ENV \
	--desc "Produuct App Electronics Store in $ENV, also used by AppSheet."

apigeecli -t $TOKEN -o $ORG developers create --email 'demo@any.com' --first Demo --last Developer --user demo-developer

apigeecli -t $TOKEN -o $ORG apps create --email 'demo@any.com' -n "Electronics Store $ENV" -p product-recommendations-v1-$ENV
export APIKEY=$(apigeecli -t $TOKEN -o $ORG apps get --name "Electronics Store $ENV" | jq .[0].credentials[0].consumerKey)

## Test
echo Testing ========================
curl https://$ENVGROUP_HOST/v1/recommendations/openapi
curl https://$ENVGROUP_HOST/v1/recommendations/products -H x-apikey:$APIKEY

