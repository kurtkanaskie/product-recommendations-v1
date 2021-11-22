# WIP - TESTING - PRIVATE USE ONLY

# Smart API to Predict Customer Propensity to buy using Apigee, BigQuery ML and Cloud Spanner
## Overview 

This demo shows how to bild a smart API that predicts customer propensity to buy using an Apigee X proxy, BigQuery ML and Cloud Spanner.

BigQuery contains a sample dataset for the complete Product Catalog Ids and a number of simulated users. 
It uses Machine Learning to predict their propensity to buy based on the time the user spends on an item, termed the "predicted session duration confidence", which is a numerical value ordered descending (higher is more likely to buy).

Cloud Spanner holds a small Product Catalog with rich content, such as descriptions and image references. 
The items are created and ordered differently than the BigQuery result (e.g ascending by the last few digits of each product Id).

Apigee exposes an API that proxies to BigQuery to get the product Ids and the "predicted session duration confidence" for a particular user and then makes a callout to Spanner to get the rich product content.
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
**NOTE:** If you don't have an Apigee X organization you can [provision an evaluation organization](https://cloud.google.com/apigee/docs/api-platform/get-started/provisioning-intro), that will require a billing account.
___

It uses [gcloud](https://cloud.google.com/sdk/gcloud) and [Maven](https://maven.apache.org/), both can be run from the GCloud shell without any installation.

The API proxy uses a separate Service Account (datareader) for GCP authentication to access Big Query and Spanner.
We'll get and use a GCP accesss token using "gcloud auth print-access-token" to deploy the proxy.


The high level steps are:
1. First [set environment variables and enable APIs](#set-environment-variables-and-enable-apis).
2. Using an existing GCP Project or after creating a GCP Project, [ceate Service Account for proxy deployment](#create-datareader-service-account).
3. Use a sample dataset to [train BigQuery to predict customer propensity](#train-bigquery-to-predict-customer-propensity).
4. Install a Product Catalog using [Setup Spanner Product Catalog](#setup-spanner-product-catalog).
5. Install Apigee X proxy using [Maven](#setup-apigee-x-proxy)

## Setup

### Set Environment Variables and Enable APIs
First set your environment variables:
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
PRODUCT_ID_1
PRODUCT_ID_2
PRODUCT_ID_3
PRODUCT_ID_4
PRODUCT_ID_5
```

### Create datareader Service Account
Create a "datareader" service account and assign Spanner and BigQuery roles. 
```
gcloud iam service-accounts create datareader --display-name="Data reader for BQ and Spanner Demo"
gcloud iam service-accounts list | grep datareader 

export SA=$(gcloud iam service-accounts list | grep datareader | cut -d" " -f12)
# e.g. datareader@your-apigeex-project-name.iam.gserviceaccount.com
echo $SA

gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA" --role="roles/spanner.databaseUser" --quiet
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA" --role="roles/spanner.databaseReader" --quiet
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA" --role="roles/bigquery.dataViewer" --quiet
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA" --role="roles/bigquery.user" --quiet
```

### Train BigQuery to Predict Customer Propensity
___
**NOTE:** Internal Google users, running the tutorial will require purchasing BigQuery flex slots which may require you to file an exemption, see [go/bq-flex-restrictions](https://g3doc.corp.google.com/cloud/helix/g3doc/reservations/flex-restrictions.md?cl=head) for more.
___

Follow the Machine Learning tutorial [Building an e-commerce recommendation system by using BigQuery ML](https://cloud.google.com/architecture/building-a-recommendation-system-with-bigqueryml), then return here to setup Spanner and Apigee. 
Once the tutorial is complete, go to the BigQuery console and 
* select the `prod_recommendations` table, 
* then click PREVIEW to view the results. 

Note the `userId` values, the API Proxy uses those in the request to get results (see below).
Select any of the `userId` values, set an environment variable and run a query against BigQuery to see the product recomendations. We'll use the `itemId` values when we set up the Spanner Product Catalog in the next step.

```
export CUSTOMER_USERID=userid-value-from-biquery

bq query --nouse_legacy_sql \
    "select * from \`$PROJECT_ID.bqml.prod_recommendations\` where userId = \"$CUSTOMER_USERID\""
+-----------------------+----------------+---------------------------------------+
|        userId         |     itemId     | predicted_session_duration_confidence |
+-----------------------+----------------+---------------------------------------+
| 6929470170340317899-1 | GGOEGAAX0037   |                     40161.10446942589 |
| 6929470170340317899-1 | GGOEGAAX0351   |                    27204.111219270915 |
| 6929470170340317899-1 | GGOEGDWC020199 |                    25863.861349754334 |
| 6929470170340317899-1 | GGOEYDHJ056099 |                     27642.28480729123 |
| 6929470170340317899-1 | GGOEGAAX0318   |                    24585.509088154067 |
+-----------------------+----------------+---------------------------------------+
```

### Setup Spanner Product Catalog

The Spanner Product Catalog only contains the items that where used in the BigQuery training step for a specific user. We'll set `productid` values that where associated to the usesrId values during the ML training step.

Create environent variables for each product Id using the values from the output of the BigQuery query above (do not use these values directly). 

NOTE: The order in which you create them, is the order in which they are returned, but since Apigee is applying the BigQuery ordering, the API response order will be different. Compare the response from the Spanner script to that from the API proxy.
```
export PRODUCT_ID_1=GGOEGAAX0037
export PRODUCT_ID_2=GGOEGAAX0318
export PRODUCT_ID_3=GGOEGAAX0351
export PRODUCT_ID_4=GGOEGDWC020199
export PRODUCT_ID_5=GGOEYDHJ056099
```

Run the [setup_spanner.sh](#setup_spanner.sh) shell script to set up Spanner Product Catalog .

Return here to setup Apigee.


### Setup Apigee X Proxy

The Apigee proxy will be deployed using Maven. 
The Maven command will create and deploy a proxy (product-recommendations-v1), create an API Product (product-recommendations-v1-$ENV), create an App Developer (demo@any.com) and App (product-recommendations-v1-app-$ENV).

Clone the repository (doesn't work in Cloud Shell).
```
git clone git@github.com:kurtkanaskie/product-recommendations-v1.git
```

Note the pom.xml file profile values for `apigee.org`, `apigee.env`, `api.northbound.domain`, `gcp.projectid`, and `googletoken.email`. These values will be set via the command line.
```
<profile>
    <id>eval</id> <!-- unique profile name -->
    <properties>
        <apigee.org>${apigeeOrg}</apigee.org>
        <apigee.env>${apigeeEnv}</apigee.env>
        <api.northbound.domain>${envGroupHostname}</api.northbound.domain>

        <gcp.projectid>${gcpProjectId}</gcp.projectid> <!-- Same as org, could be remote project for BQ and Spanner -->
        <apigee.googletoken.email>${googleTokenEmail}</apigee.googletoken.email> <!-- SA Email for GCP Auth in Proxy -->
    </properties>
</profile>
```

Run Maven to install the proxy and it's associated artifacts and then test the API, all in one command.
```
mvn -P eval clean install \
    -Dbearer=$(gcloud auth print-access-token) \
    -DapigeeOrg=$ORG \
    -DapigeeEnv=$ENV \
    -DenvGroupHostname=$ENVGROUP_HOSTNAME \
    -DgcpProjectId=$PROJECT_ID \
    -DgoogleTokenEmail=$SA
```
The result of the maven command shows the integration test output, one to `/openapi` and another to `/products`.
It also displays the App credentials which can be used for susequent API calls. 

#### Testing the API Proxy

You can get the API Key for the App using the Apigee API:
```
APIKEY=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    https://apigee.googleapis.com/v1/organizations/$ORG/developers/demo@any.com/apps/product-recommendations-v1-app-$ENV | jq -r .credentials[0].consumerKey)
```

Then test using curl, for example:
```
curl -s https://$ENVGROUP_HOSTNAME/v1/recommendations/products -H x-apikey:$APIKEY | jq
```

The API defined by the Open API Specification in [product-recommendations-v1-oas.yaml](product-recommendations-v1-oas.yaml) allows the request to specify headers:
* x-apikey: the App consumer key as per security scheme
* x-userid: the user identifier making the request (defaults to 8147666854244452077-2 in the proxy if not provided).
* cache-control: cache the response for 300 seconds or override by specifying "no-cache".

Example:
```
curl -s --location --request GET "https://$ENVGROUP_HOSTNAME/v1/recommendations/products" \
--header "x-apikey:$APIKEY" \
--header "x-userid:$CUSTOMER_USERID" \
--header "Cache-Control:no-cache" | jq
```

## Cleanup

### Cleanup Apigee

Run Maven to undeploy and delete proxy and it's associated artifacts, all in one command.
```
mvn -P $ENV -Dbearer=$(gcloud auth print-access-token) -Dskip.integration=true \
    apigee-config:apps apigee-config:apiproducts apigee-config:developers -Dapigee.config.options=delete \
    apigee-enterprise:deploy -Dapigee.options=clean
```

### Cleanup Spanner
Remove the Spanner resources by running the [cleanup_spanner.sh](#cleanup_spanner.sh) shell script.

### Cleanup BigQuery
Cleanup BigQuery using the [Cleanup components](https://cloud.google.com/architecture/predicting-customer-propensity-to-buy#delete_the_components) from the tutorial rather than deleting the project as you may want to continue to use Apigee X.

### Delete Service Account
```
export SA=$(gcloud iam service-accounts list | grep datareader | cut -d" " -f12)
gcloud iam service-accounts delete $SA
```


