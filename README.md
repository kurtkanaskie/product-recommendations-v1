# product-recommendations-v1 (WIP - DO NOT USE)

## Prerequisites

This example uses [gcloud](https://cloud.google.com/sdk/gcloud) and [Maven](https://maven.apache.org/), both can be run from the GCloud shell without any installation.
### Using gcloud and maven (TBD)

In the project open the cloud shell.
```
git clone git@github.com:kurtkanaskie/product-recommendations-v1.git
```
* Create and download Serice Account with `Apigee Orgadmin` Role 
* Modify the pom.xml file to use the downloaded Service Account
* Run Maven to install proxy and it's associated artifacts and then test the API
```
mvn -P test install
```

#### Cloud Build (TBD)
* Edit cloudbuild-test.yaml and set variables
* Modify `gcloud-secret-keys.sh`:
  * Create keyring and key to encrypt username and SA key.
  * Encrypt username (SA email) and key (downloaded-key.json)
```
cloud-build-local --dryrun=true --config=cloudbuild-dev.yaml --substitutions=BRANCH_NAME=local-gcloud,COMMIT_SHA=none .
```

### Using apigeecli
You can also use apigeecli, however that requires [Homebrew](https://docs.brew.sh/Homebrew-on-Linux) which is not available in GCloud by default.

It's easy to set up. In the project open the cloud shell:
1. Install brew:
```
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
 * Follow the instructions to add brew to your path, they're shown on the output from the script. **NOTE:** You may need to change permissions, just follow the suggestions when the situation occurs.
```
brew tap srinandan/homebrew-tap
brew install apigeecli
apigecli help
```

## Setup Apigee using gcloud and apigeecli

Edit the `setup-apigee.sh` to set environment variables:
```
export TOKEN=$(gcloud auth print-access-token)
export ORG=ngsaas-5g-kurt
export ENV=test-1
export ENVGROUP_HOST=napi-test.kurtkanaskie.net
```
Then run `setup-apigee.sh`

The script:
* Sets the active project
* Creates a Service Account in your Apigee X project for use with the proxy
* Creates and deploys the ``product-recommendations-v1` proxy
* Creates API Product, App Developer and App
* Tests the proxy using:
 * curl https://$ENVGROUP_HOST/v1/recommendations/openapi
 * curl https://$ENVGROUP_HOST/v1/recommendations/products -H x-apikey:$APIKEY

## Clean up Apigee using gcloud and apigeecli
Edit the `cleanup-apigee.sh` to set environment variables and then run `cleanup-apigee.sh`
The script:
* Deletes Service Account
* Deletes the App, Developer and API Product
* Undeploys and deletes the proxy