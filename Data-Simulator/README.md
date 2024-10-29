## Environment Preparation

Before you jump into the challenges make sure you GCP project is prepared by: 

Clone the github repo.
```
git clone https://github.com/NucleusEngineering/data-journey
cd data-journey/Data-Simulator
```

Enable Google Cloud APIs. (also create gcr.io repo before tf script)
```
gcloud services enable compute.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com dataflow.googleapis.com run.googleapis.com dataflow.googleapis.com pubsub.googleapis.com serviceusage.googleapis.com bigquery.googleapis.com containerregistry.googleapis.com
```
Open Cloud Shell Editor and change the project id in `./terraform.tfvars` to your own project id.

Build the basic permissions & networking setup via terraform apply.

```
terraform init -upgrade
```

```
terraform apply -var-file terraform.tfvars
```


<!-- ### Organizational Policies

Depending on the setup within your organization you might have to [overwrite some organizational policies](https://cloud.google.com/resource-manager/docs/organization-policy/creating-managing-policies#boolean_constraints) for the examples to run.

For example, the following policies should not be enforced. 

```
constraints/sql.restrictAuthorizedNetworks
constraints/compute.vmExternalIpAccess
constraints/compute.requireShieldedVm
constraints/storage.uniformBucketLevelAccess
constraints/iam.allowedPolicyMemberDomains
``` -->

## Validate Event Ingestion

Open Cloud Shell Editor and enter your GCP Project ID, the GCP Region and the endpoint URL in ./config_env.sh. The endpoint URL refers to the URL of the proxy container deployed to Cloud Run with the streaming data input. To find it, either find the service in the Cloud Run UI, or run the following gcloud command and copy the URL:

```
gcloud run services list
```

Set all necessary environment variables by running:

```
source config_env.sh
```

You can now stream website interaction data points through a Cloud Run Proxy Service into your Pub/Sub Topic.

The script `synth_json_stream.py` contains everything you need to simulate a stream.
Run to direct an artificial click stream at your pipeline.

```
python3 synth_json_stream.py --endpoint=$ENDPOINT_URL --bucket=$BUCKET --file=$FILE
```

After a minute or two validate that your solution is working by inspecting the [metrics](https://cloud.google.com/pubsub/docs/monitor-topic) of your Pub/Sub topic.
Of course the topic does not have any consumers yet. Thus, you should find that messages are queuing up.

By default you should see around .5 messages per second streaming into the topic.
