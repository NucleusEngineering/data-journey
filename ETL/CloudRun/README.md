# Apply simple transformations and bring data to BigQuery as cost-efficient as possible
ELT is a relatively new concept. Cheap availability of Data Warehouses allows efficient on-demand transformations. That saves storage and increases flexibility. All you have to manage are queries, not transformed datasets. And you can always go back to data in it's raw form.

Although, sometimes it just makes sense to apply transformation on incoming data directly. 
What if we need to apply some general cleaning, or would like to apply machine learning inference on the incoming data at the soonest point possible?

Traditional [ETL](https://cloud.google.com/bigquery/docs/migration/pipelines#etl) is a proven concept to do just that.

But ETL tools are maintenance overhead. In our example, you don't want to manage a Spark, GKE cluster or similar.Specifically, your requirement is a serverless and elastic ETL pipeline.

That means your pipeline should scale down to 0 when unused or up to whatever is needed to cope with a higher load.

To start off, let's reference the working directory:

```
cd ETL/CloudRun
```

## STEP 1

First component of our lightweight ETL pipeline is a BigQuery Table named `cloud_run`.
The BigQuery Table should make use of the schema file `./schema.json`.
The processing service will stream the transformed data into this table.

Run this command

```
bq mk --location=europe-west1 --table $GCP_PROJECT:data_journey.cloud_run ./schema.json
```

OR follow the documentation on how to [create a BigQuery table with schema through the console](https://cloud.google.com/bigquery/docs/tables#console).

!!! Note: Check BQ schema for "weekday" column. Create it if needed.

</details>

## STEP 2
Second, let's set up your Cloud Run Processing Service. `./ETL/CloudRun` contains all the necessary files.

Inspect the `Dockerfile` to understand how the container will be build.

`main.py` defines the web server that handles the incoming data points. Inspect `main.py` to understand the web server logic.

Make sure to replace the required variables in `config.py` so you can access them safely in `main.py`.

Once the code is completed build the container from `./ETL/CloudRun` into a new container repository named `data-processing-service`.

```
gcloud builds submit $RUN_PROCESSING_DIR --tag gcr.io/$GCP_PROJECT/data-processing-service
```

Validate the successful build with:

```
gcloud container images list
```

You should see something like:
```
NAME: gcr.io/<project-id>/pubsub-proxy
NAME: gcr.io/<project-id>/data-processing-service
Only listing images in gcr.io/<project-id>. Use --repository to list images in other repositories.
```

</details>

## STEP 3

Next step is to deploy a new cloud run processing service based on the container you just build to your Container Registry.

```
gcloud run deploy dj-run-service-data-processing --image gcr.io/$GCP_PROJECT/data-processing-service:latest --region=europe-west1 --allow-unauthenticated
```

</details>


## Step 4

Define a Pub/Sub subscription named `dj-subscription_cloud_run` that can forward incoming messages to an endpoint.

You will need to create a Push Subscription to the Pub/Sub topic we already defined.


Enter the displayed URL of your processing in `./config_env.sh` as `PUSH_ENDPOINT` & reset the environment variables.

```
source config_env.sh
```

Create PubSub push subscription: 
```
gcloud pubsub subscriptions create dj-subscription_cloud_run \
    --topic=dj-pubsub-topic \
    --push-endpoint=$PUSH_ENDPOINT
```

OR 

read it can be [defined via the console](https://cloud.google.com/pubsub/docs/create-subscription#pubsub_create_push_subscription-console).

</details>

## Check schema again. [add weekday time - string, not date time, nullable]
## Validate lightweight ETL pipeline implementation

You can now stream website interaction data points through your Cloud Run Proxy Service, Pub/Sub Topic & Subscription, Cloud Run Processing and all the way up to your BigQuery destination table.

Just before you sunt the script, edit schema and add "weekday" of type string, not date time, nullable.

Run 

```
python3 synth_json_stream.py --endpoint=$ENDPOINT_URL --bucket=$BUCKET --file=$FILE
```

to direct an artificial click stream at your pipeline. No need to reinitialize if you still have the clickstream running from earlier.

After a minute or two you should find your BigQuery destination table populated with data points. 
The metrics of Pub/Sub topic and Subscription should also show the throughput.
Take a specific look at the un-acknowledged message metrics in Pub/Sub.
If everything works as expected it should be 0.
