#! /bin/bash

echo; echo Using Apigee X project \"$PROJECT_ID\", instance \"$SPANNER_INSTANCE\", database \"$SPANNER_DATABASE\" in region \"$REGION\"
read -p "OK to proceed (Y/n)? " i
if [ "$i" != "Y" ]
then
  echo aborted
  exit 1
fi
echo Proceeding...

# Set project for gcloud commands 
gcloud config set project $PROJECT_ID

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
--data=productid=$PRODUCT_ID_1,description="Bamboo glass jar",discount=0,image="products_Images/1.image.181347.jpg",name="Bamboo glass jar",price=19.99

gcloud spanner rows insert --database=$SPANNER_DATABASE --table=products \
--data=productid=$PRODUCT_ID_2,description="Hotest hairdryer",discount=0,image="products_Images/2.image.182110.jpg",name="Hairdryer",price=84.99

gcloud spanner rows insert --database=$SPANNER_DATABASE --table=products \
--data=productid=$PRODUCT_ID_3,description="Most comfortable loafers",discount=0,image="products_Images/3.image.182234.jpg",name="Loafers",price=38.99

gcloud spanner rows insert --database=$SPANNER_DATABASE --table=products \
--data=productid=$PRODUCT_ID_4,description="Best Coffee Mug",discount=0,image="products_Images/4.image.181817.jpg",name="Coffee Mug",price=4.20

gcloud spanner rows insert --database=$SPANNER_DATABASE --table=products \
--data=productid=$PRODUCT_ID_5,description="The ultimate sunglasses",discount=0,image="products_Images/5.image.181026.jpg",name="Aviator Sunglasses",price=42.42

gcloud spanner databases execute-sql $SPANNER_DATABASE --sql='SELECT * FROM products'



