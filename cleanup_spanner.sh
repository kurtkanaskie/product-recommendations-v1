#! /bin/bash

export PROJECT=apigeex-mint-kurt
export SPANNER_INSTANCE=product-catalog
export SPANNER_DATABASE=product-catalog-v1
export REGION=regional-us-east1

echo; echo Using Apigee X project \"$PROJECT\", instance \"$SPANNER_INSTANCE\", database \"$SPANNER_DATABASE\" in region \"$REGION\"
read -p "OK to proceed (Y/n)? " i
if [ "$i" != "Y" ]
then
  echo aborted
  exit 1
fi
echo Proceeding...

# Set project for gcloud commands 
gcloud config set project $PROJECT

# Using gcloud: https://cloud.google.com/spanner/docs/getting-started/gcloud
# Create instance
gcloud spanner databases delete $SPANNER_DATABASE --quiet

gcloud spanner instances delete $SPANNER_INSTANCE --quiet