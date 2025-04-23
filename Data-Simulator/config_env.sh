#!/bin/sh

# Copyright 2023 Google LLC
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export GCP_PROJECT="<PROJECT-ID>"

export ENDPOINT_URL="<ENDPOINT URL>" # doesn't need to be defined in the very beginning
export GCP_REGION="europe-west1"
export DATAFLOW_TEMPLATE=dataflow
export RUN_PROXY_DIR=cloud-run-pubsub-proxy
# export RUN_PROCESSING_DIR=data-processing-service # only needed for /ETL/CloudRun
# export PUSH_ENDPOINT="<processing-endpoint-url>" # only needed for /ETL/CloudRun

export BUCKET=example-bucket-name-$GCP_PROJECT
export FILE=extract


#don't use - different use case backup
# GCP_USER_EMAIL="<GCP-USER-EMAIL>"
# username=$(echo "$GCP_USER_EMAIL" | cut -d'@' -f1)
# export GCP_USERNAME=$username
