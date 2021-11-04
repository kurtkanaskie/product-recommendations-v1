# product-recommendations-v1



## Setup Apigee

Edit the `setup-apigee.sh` to set environment variables:
```
export TOKEN=$(gcloud auth print-access-token)
export ORG=ngsaas-5g-kurt
export ENV=test-1
export ENVGROUP_HOST=napi-test.kurtkanaskie.net
```
Then run `setup-apigee.sh`

The script:
* Set the active project
* Creates a Service Account in your Apigee X project for use with the proxy
* Creates and deploys the ``product-recommendations-v1` proxy
* Creates API Product, App Developer and App
* Tests the proxy using:
 * curl https://$ENVGROUP_HOST/v1/recommendations/openapi
 * curl https://$ENVGROUP_HOST/v1/recommendations/products -H x-apikey:$APIKEY

## Clean up Apigee
Edit the `cleanup-apigee.sh` to set environment variables and then run `cleanup-apigee.sh`
The script:
* Deletes Service Account
* Deletes the App, Developer and API Product
* Undeploys and deletes the proxy