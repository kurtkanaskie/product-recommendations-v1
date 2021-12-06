id: product-recommendations-v1

# WIP - TESTING - PRIVATE USE ONLY

# Smart API to Predict Customer Propensity to buy using Apigee, BigQuery ML and Cloud Spanner
## Overview 

This demo shows how to bild a smart API that predicts customer propensity to buy using an Apigee X proxy, BigQuery ML and Cloud Spanner.

BigQuery contains a sample dataset for the complete Product Catalog Ids and a number of simulated users. 
It uses Machine Learning to predict their propensity to buy based on the time the user spends viewing an item, termed the "predicted session duration confidence", which is a numerical value ordered descending (higher is more likely to buy).

Cloud Spanner simulates a Product Catalog with rich content, such as descriptions and image references. The demo only contains entries for a specific customer Id.
The items are created and ordered differently than the BigQuery result (e.g ascending by the last few digits of each product Id).

Apigee exposes an API that proxies to BigQuery to get the product Ids and the "predicted session duration confidence" for a particular user and then makes a callout to Spanner to get the additional product content.
The proxy then uses both responses to create the priority sorted result that is sent in the response.

### Architecture Diagram
![Architecture Diagram](product-recommendations-v1.png)

Step Descriptions:
1. Client request to GET /v1/recommendations/products with API Key and User Id.
2. Apigee extracts user Id from request header, creates a SQL query using Assign Message policy, sends that to BigQuery and processes the response.
3. Apigee creates a Spanner session via Service Callout policy and stores the session name.
4. Apigee then creates a SQL query for Spanner using another Service Callout policy to get the ordered response based on the BigQuery prepensity rating returned from BigQuery.
5. Finally, Apigee formats the response using JavaScript to match the response definition from the Open API Specification.

## Prerequisites 

This demo relies on the use of a GCP Project for [Apigee X](), [Big Query]() and [Cloud Spanner](). 

___
**NOTE:** If you don't have an Apigee X organization you can <a href="https://cloud.google.com/apigee/docs/api-platform/get-started/provisioning-intro" target="_blank">provision an evaluation organization</a>, that will require a billing account.

___

It uses [gcloud](https://cloud.google.com/sdk/gcloud) and [Maven](https://maven.apache.org/), both can be run from the GCloud shell without any installation.

The API proxy uses a Service Account (e.g. datareader) for GCP authentication to access Big Query and Spanner.
We'll use the project owner to get a GCP accesss token using "gcloud auth print-access-token" to deploy the proxy.


The high level steps are:
1. First [clone this repository](#clone-repository).
2. Then [set environment variables](#set-environment-variables) and [enable APIs](#enable-apis).
3. Using an existing GCP Project or after creating a GCP Project, [ceate Service Account for proxy deployment](#create-datareader-service-account).
4. Use a sample dataset to [train BigQuery to predict customer propensity](#train-bigquery-to-predict-customer-propensity).
5. Install a Product Catalog using [Setup Spanner Product Catalog](#setup-spanner-product-catalog).
6. Install Apigee X proxy using [Maven](#setup-apigee-x-proxy)

## Setup
Duration: 0:30:00 (if you don't already have Apigee X) 0:10:00 (otherwise)

### Clone Repository
```
git clone https://github.com/kurtkanaskie/product-recommendations-v1
cd product-recommendations-v1
```

### Set Environment Variables
Set your environment variables (TIP: create a set_env_variables.sh file with these for easy replay):
```
export PROJECT_ID=your_apigeex_project_name
export ORG=$PROJECT_ID
export ENV=eval
export ENVGROUP_HOSTNAME=api.yourdomain.net
export SPANNER_INSTANCE=product-catalog
export SPANNER_DATABASE=product-catalog-v1
export REGION=regional-us-east1
```
Other environment variables that are set below
```
SA 
CUSTOMER_USERID
APIKEY
```

### Enable APIs
Enable APIs for BigQuery and Spanner.
```
gcloud services enable bigquery.googleapis.com 
gcloud services enable spanner.googleapis.com
```

### Create datareader Service Account
Create a "datareader" service account and assign Spanner and BigQuery roles. 
```
gcloud iam service-accounts create datareader --display-name="Data reader for BQ and Spanner Demo"
gcloud iam service-accounts list | grep datareader 

# For Cloud Shell
export SA=$(gcloud iam service-accounts list | grep datareader | cut -d" " -f2)
# From Mac the response includes the description
# export SA=$(gcloud iam service-accounts list | grep datareader | cut -d" " -f12)

# e.g. datareader@your-apigeex-project-name.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA" --role="roles/spanner.databaseUser" --quiet
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA" --role="roles/spanner.databaseReader" --quiet
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA" --role="roles/bigquery.dataViewer" --quiet
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA" --role="roles/bigquery.user" --quiet

echo Service Account is: $SA

```

## Train BigQuery to Predict Customer Propensity
Duration: 0:30:00

___
**NOTE:** Internal Google users, running the tutorial will require purchasing BigQuery flex slots which may require you to file an exemption, see [go/bq-flex-restrictions](https://g3doc.corp.google.com/cloud/helix/g3doc/reservations/flex-restrictions.md?cl=head) for more.
___

Follow the Machine Learning tutorial [Building an e-commerce recommendation system by using BigQuery ML](https://cloud.google.com/architecture/building-a-recommendation-system-with-bigqueryml), then return here to setup Spanner and Apigee. 
Once the tutorial is complete, go to the BigQuery console and 
* select the `prod_recommendations` table, 
* then click PREVIEW to view the results. 

Note the `userId` values, the API Proxy uses those in the request to get results (see below).
Select any of the `userId` values, set an environment variable and run a query against BigQuery to see the product recomendations. We'll use the `itemId` values when we set up the Spanner Product Catalog in the next step.

Next run the BigQuery query command to show the "prediction" ordered results.
For example:

```
export CUSTOMER_USERID=6929470170340317899-1

bq query --nouse_legacy_sql \
    "SELECT * FROM \`$PROJECT_ID.bqml.prod_recommendations\` AS A where A.userid = \"$CUSTOMER_USERID\"" \
    ORDER BY A.predicted_session_duration_confidence DESC
```
Example response:
```
+-----------------------+----------------+---------------------------------------+
|        userId         |     itemId     | predicted_session_duration_confidence |
+-----------------------+----------------+---------------------------------------+
| 6929470170340317899-1 | GGOEGAAX0037   |                     40161.10446942589 |
| 6929470170340317899-1 | GGOEYDHJ056099 |                     27642.28480729123 |
| 6929470170340317899-1 | GGOEGAAX0351   |                    27204.111219270915 |
| 6929470170340317899-1 | GGOEGDWC020199 |                    25863.861349754334 |
| 6929470170340317899-1 | GGOEGAAX0318   |                    24585.509088154067 |
+-----------------------+----------------+---------------------------------------+
```

## Setup Spanner Product Catalog
Duration: 0:10:00

The Spanner Product Catalog will only contain the items that where used in the BigQuery training step for a specific user. We'll create product entries using those `itemID`s. This means that if you change the  `CUSTOMER_USERID` you may see different results or sparse results as Spanner does not contain the entire product catalog.

NOTE: The order in which the items are returned from Spanner is different than those returned from BigQuery. This allows us to observe the differences from the "prediction".

Run the [setup_spanner.sh](#setup_spanner.sh) shell script to set up Spanner Product Catalog.
It uses the `CUSTOMER_USERID` and outputs the entries that where created. 

You can also run a gcloud command to view, for example:
```
gcloud spanner databases execute-sql $SPANNER_DATABASE --sql='SELECT * FROM products'
```
Sample response:
```
productid       name                description               price  discount  image
GGOEGAAX0037    Aviator Sunglasses  The ultimate sunglasses   42.42  0         products_Images/sunglasses.jpg
GGOEGAAX0318    Bamboo glass jar    Bamboo glass jar          19.99  0         products_Images/bamboo-glass-jar.jpg
GGOEGAAX0351    Loafers             Most comfortable loafers  38.99  0         products_Images/loafers.jpg
GGOEGDWC020199  Hairdryer           Hotest hairdryer          84.99  0         products_Images/hairdryer.jpg
GGOEYDHJ056099  Coffee Mug          Best Coffee Mug           4.2    0         products_Images/mug.jpg
```

## Setup Apigee X Proxy
Duration: 0:10:00

The Apigee proxy will be deployed using Maven. 
The Maven command will create and deploy a proxy (product-recommendations-v1), create an API Product (product-recommendations-v1-$ENV), create an App Developer (demo@any.com) and App (product-recommendations-v1-app-$ENV).

Note the pom.xml file profile values for `apigee.org`, `apigee.env`, `api.northbound.domain`, `gcp.projectid`, `googletoken.email` and `api.userid`. These values will be set via the command line.
```
<profile>
	<id>eval</id>
	<properties>
		<apigee.profile>eval</apigee.profile>
		<apigee.org>${apigeeOrg}</apigee.org>
		<apigee.env>${apigeeEnv}</apigee.env>
		<api.northbound.domain>${envGroupHostname}</api.northbound.domain>
		<gcp.projectid>${gcpProjectId}</gcp.projectid>
		<apigee.googletoken.email>${googleTokenEmail}</apigee.googletoken.email>
		<api.userid>${customerUserId}</api.userid>
	</properties>
</profile>
```

Run Maven to install the proxy and it's associated artifacts and then test the API, all in one command.
```
mvn -P eval clean install -Dbearer=$(gcloud auth print-access-token) \
    -DapigeeOrg=$ORG \
    -DapigeeEnv=$ENV \
    -DenvGroupHostname=$ENVGROUP_HOSTNAME \
    -DgcpProjectId=$PROJECT_ID \
    -DgoogleTokenEmail=$SA \
    -DcustomerUserId=$CUSTOMER_USERID
```
The result of the maven command shows the integration test output, one to `/openapi` and another to `/products`.
It also displays the App credentials which can be used for susequent API test calls. 

## Testing the API Proxy
Duration: 0:10:00

You can get the API Key for the App using the Apigee API:
```
APIKEY=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    https://apigee.googleapis.com/v1/organizations/$ORG/developers/demo@any.com/apps/product-recommendations-v1-app-$ENV \
    | jq -r .credentials[0].consumerKey)
```

Then test using curl, for example:
```
curl -s https://$ENVGROUP_HOSTNAME/v1/recommendations/products -H x-apikey:$APIKEY -H "x-userid:$CUSTOMER_USERID" | jq
```

The API defined by the Open API Specification in [product-recommendations-v1-oas.yaml](product-recommendations-v1-oas.yaml) allows the request to specify headers:
* x-apikey: the App consumer key as per security scheme
* x-userid: the user identifier making the request (defaults to 6929470170340317899-1 in the proxy if not provided).
* cache-control: cache the response for 300 seconds or override by specifying "no-cache".

Example:
```
curl -s "https://$ENVGROUP_HOSTNAME/v1/recommendations/products" \
-H "x-apikey:$APIKEY" \
-H "x-userid:$CUSTOMER_USERID" \
-H "Cache-Control:no-cache" | jq
```
Example response:
```
{
  "products": [
    {
      "productid": "GGOEGAAX0037",
      "name": "Aviator Sunglasses",
      "description": "The ultimate sunglasses",
      "price": "42.42",
      "image": "products_Images/sunglasses.jpg"
    },
    {
      "productid": "GGOEYDHJ056099",
      "name": "Coffee Mug",
      "description": "Best Coffee Mug",
      "price": "4.2",
      "image": "products_Images/mug.jpg"
    },
    {
      "productid": "GGOEGAAX0351",
      "name": "Loafers",
      "description": "Most comfortable loafers",
      "price": "38.99",
      "image": "products_Images/loafers.jpg"
    },
    {
      "productid": "GGOEGDWC020199",
      "name": "Hairdryer",
      "description": "Hotest hairdryer",
      "price": "84.99",
      "image": "products_Images/hairdryer.jpg"
    },
    {
      "productid": "GGOEGAAX0318",
      "name": "Bamboo glass jar",
      "description": "Bamboo glass jar",
      "price": "19.99",
      "image": "products_Images/bamboo-glass-jar.jpg"
    }
  ]
}

```

**KEY TAKEAWAY**: the order of the items in the API response is that provided by BigQuery and is a different order than the output from Spanner. That's becasue the API proxy first gets the "prediction" ordered results from BigQuery and then combines that with the product details from Spanner.


## Cleanup
Duration: 0:10:00
### Cleanup Apigee

Run Maven to undeploy and delete proxy and it's associated artifacts, all in one command.
```
mvn -P eval process-resources -Dbearer=$(gcloud auth print-access-token) \
    -DapigeeOrg=$ORG -DapigeeEnv=$ENV -Dskip.integration=true \
    apigee-config:apps apigee-config:apiproducts apigee-config:developers -Dapigee.config.options=delete \
    apigee-enterprise:deploy -Dapigee.options=clean
```

### Cleanup Spanner
Remove the Spanner resources by running the [cleanup_spanner.sh](#cleanup_spanner.sh) shell script.

### Cleanup BigQuery
Cleanup BigQuery using the [Cleanup components](https://cloud.google.com/architecture/predicting-customer-propensity-to-buy#delete_the_components) from the tutorial rather than deleting the project as you may want to continue to use Apigee X.

### Delete Service Account
```
gcloud iam service-accounts delete $SA
```


