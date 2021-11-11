#! /bin/bash

export PROJECT=ngsaas-5g-kurt
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

# Enable API
# Console: https://pantheon.corp.google.com/apis/library/spanner.googleapis.com
gcloud services enable spanner.googleapis.com

# Using gcloud: https://cloud.google.com/spanner/docs/getting-started/gcloud
# Create instance
gcloud spanner instances create $SPANNER_INSTANCE --config=$REGION --description="Product Catalog Instance" --nodes=1

# Set default instance
gcloud config set spanner/instance $SPANNER_INSTANCE

gcloud spanner databases create $SPANNER_DATABASE --instance $SPANNER_INSTANCE

# Create database
gcloud spanner databases ddl update $SPANNER_DATABASE \
--ddl='CREATE TABLE products (productid STRING(20) NOT NULL, name STRING(100), description STRING(1024), price FLOAT64, discount FLOAT64, image STRING(1024)) PRIMARY KEY(productid);'

# Create data
gcloud spanner rows insert --database=$SPANNER_DATABASE --table=products \
--data=productid=GGOEGAAX0568,description="The ultimate 5G Google phone.",discount=0,image=pixel.jpeg,name="Google Pixel 5",price=601.99

gcloud spanner rows insert --database=$SPANNER_DATABASE --table=products \
--data=productid=GGOEGAAX0690,description="Google Pixel Buds",discount=0,image=pixel-buds.jpeg,name="Pixel Buds",price=152.15

gcloud spanner rows insert --database=$SPANNER_DATABASE --table=products \
--data=productid=GGOEGDHB072199,description="Google Pixelbook Go",discount=0,image=pixelbook.png,name="Pixelbook",price=584.10

gcloud spanner rows insert --database=$SPANNER_DATABASE --table=products \
--data=productid=GGOEGFKQ020399,description="Fitbit Versa 3 Smartwatch",discount=0,image=watch.jpeg,name="Fitbit Versa 3",price=229.95

gcloud spanner rows insert --database=$SPANNER_DATABASE --table=products \
--data=productid=GGOEGHPB003410,description="Stadia Primiere Edition",discount=0,image=stadia.jpeg,name="Stadia Premiere Edition",price=69.99

gcloud spanner databases execute-sql $SPANNER_DATABASE --sql='SELECT * FROM products'

