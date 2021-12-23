#! /bin/bash
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Example script to set environmenet variables.

# Change to your values
export PROJECT_ID=your_org_name
export ORG=$PROJECT_ID
export ENV=your_env
export ENVGROUP_HOSTNAME=your_api_domain_name
export CUSTOMER_USERID="your_user_id"

# No need to change these
export SPANNER_INSTANCE=product-catalog
export SPANNER_DATABASE=product-catalog-v1
export SPANNER_REGION=regional-us-east1
export SA=datareader@$PROJECT_ID.iam.gserviceaccount.com
export SA_INSTALLER=demo-installer@$PROJECT_ID.iam.gserviceaccount.com
