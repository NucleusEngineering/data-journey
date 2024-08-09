<walkthrough-metadata>
  <meta name="title" content="Welcome to Cloud Native Data Journey with Google Cloud!" />
  <meta name="description" content="This walkthrough describes how to build an end-to-end data pipeline, from collection, over transformation and up to activation of the data." />
  <meta name="keywords" content="data,bigquery,dataflow,cloudrun,etl,elt" />
  <meta name="component_id" content="1163696" /> #
</walkthrough-metadata>

# Cloud Native Data Journey on Google Cloud

## End-to-End Data Pipeline for Mobile Game User Retention

This walkthrough guides you through the process of constructing a complete data pipeline, encompassing:

* **Data Collection:** Gathering raw event data from a real mobile gaming app (Flood It) via Google Analytics for Firebase.
* **Data Transformation:** Processing and structuring the nested event data for analysis.
* **Data Activation:** Utilizing the transformed data to build a machine learning model for predicting user retention.

### Data

* **Source:** Google Analytics for Firebase
* **Type:** Raw event data from the Flood It mobile game
* **Structure:** Each row represents an event, with event characteristics stored in a nested format.
* **Events:** 
    * Predefined events automatically logged by Google Analytics.
    * Custom events defined by developers for additional insights.

### Goal

Develop a machine learning propensity model to predict the likelihood of users returning to the app, addressing the challenge of user retention in mobile game development. 

### Architecture

[Click here to see an image from the architecture we'll be about to use.](https://github.com/NucleusEngineering/data-journey/blob/main/rsc/architecture.png)

### Aspiration

By the end of this workshop, you will learn how to:

* Stream the raw event data into messaging queue **(/Data-Simulator)**
* Transform the data using different transformation tools **(/ETL)**
* Transform the data once it is loaded into BigQuery **(/ELT)**
* Synchronize the data in MySQL and BigQuery **(/CDC)**
* Train ML model Using BigQueryML and automate your ML workflow using Vertex ML Pipelines **(/ML)**

## Project setup

Before starting on our data journey, we need to select or create a Google Cloud Project.

GCP organizes resources into projects. This allows you to
collect all of the related resources for a single application in one place.

Begin by creating a new project or selecting an existing project for this
tutorial.

For details, see
[Creating a project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project).

### Turn on Google Cloud APIs

Enable the following Google Cloud APIs:

<walkthrough-enable-apis apis=
  "compute.googleapis.com,
  cloudbuild.googleapis.com, artifactregistry.googleapis.com, 
  dataflow.googleapis.com, run.googleapis.com, pubsub.googleapis.com, serviceusage.googleapis.com, bigquery.googleapis.com, containerregistry.googleapis.com">
</walkthrough-enable-apis>

To get started, click **Start**

## Part 1: Data-Simulator

<walkthrough-tutorial-duration duration="60"></walkthrough-tutorial-duration>
<walkthrough-tutorial-difficulty difficulty="3"></walkthrough-tutorial-difficulty>

Let's build the first step in the Data Journey by setting up a messaging stream for our data.

### Environment Preparation

We have to make sure your GCP project is prepared by:

Clone the github repo we'll be using in this walkthrough.

```bash
git clone https://github.com/NucleusEngineering/data-journey
cd data-journey/Data-Simulator
``` 

<walkthrough-info-message>Open Cloud Shell Editor and change the project id in `./terraform.tfvars` to your own project id.</walkthrough-info-message>
```bash
nano terraform.tfvars
```
Change the ID and click `ctrl+S` and `ctrl+X` to save and return to the shell.

Build the basic permissions & networking setup via terraform apply.

```bash
terraform init -upgrade
```

```bash
terraform apply -var-file terraform.tfvars
```

## Validate Event Ingestion

Open Cloud Shell Editor and enter your GCP Project ID, the GCP Region and the endpoint URL in `./config_env.sh`. The endpoint URL refers to the URL of the proxy container deployed to Cloud Run with the streaming data input. To find it, either find the service in the Cloud Run UI, or run the following gcloud command and copy the URL:

```bash
gcloud run services list
```

After, enter the variables in the config file. You can open it
<walkthrough-editor-open-file filePath="config_env.sh">
in the Cloud Shell Editor
</walkthrough-editor-open-file>
to read or edit it.

Set all necessary environment variables by running:

```bash
source config_env.sh
```

You can now stream website interaction data points through a Cloud Run Proxy Service into your Pub/Sub Topic.

The script `synth_json_stream.py` contains everything you need to simulate a stream. Run to direct an artificial click stream at your pipeline.

```bash
python3 synth_json_stream.py --endpoint=$ENDPOINT_URL --bucket=$BUCKET --file=$FILE
```

After a minute or two validate that your solution is working by inspecting the [metrics](https://cloud.google.com/pubsub/docs/monitor-topic) of your Pub/Sub topic. Of course the topic does not have any consumers yet. Thus, you should find that messages are queuing up.

By default you should see around .5 messages per second streaming into the topic.

## Bring raw data to BigQuery

Now that your data ingestion is working correctly we move on to set up your processing infrastructure. Data processing infrastructures often have vastly diverse technical and business requirements. We will find the right setup for three completely different settings.

[ELT is in!](https://cloud.google.com/bigquery/docs/migration/pipelines#elt) Imagine you don't actually want to set up processing. Instead, you would like to build [a modern Lakehouse structure](https://cloud.google.com/blog/products/data-analytics/open-data-lakehouse-on-google-cloud) with ELT processing. Therefore, your main concern at this point is to bring the incoming raw data into your Data Warehouse as cost-efficient as possible. Data users will worry about the processing.

To start out we aim for rapid iteration. We plan using BigQuery as Data Lakehouse - Combining Data Warehouse and Data Lake.

To implement our lean ELT pipeline we need:

* BigQuery Dataset
* BigQuery Table
* Pub/Sub BigQuery Subscription

Start with creating a BigQuery Dataset named `data_journey`. The Dataset should contain a table named `pubsub_direct`.

Continue by setting up a Pub/Sub Subscription named `dj_subscription_bq_direct` that directly streams incoming messages in the BigQuery Table you created.

To create the BigQuery Dataset run:

```bash
bq --location=$GCP_REGION mk --dataset $GCP_PROJECT:data_journey
```

To create the BigQuery destination table run:

```bash
bq mk --location=$GCP_REGION --table $GCP_PROJECT:data_journey.pubsub_direct data:STRING
```
Alternatively create the [Dataset](https://cloud.google.com/bigquery/docs/datasets#create-dataset) and [Table](https://cloud.google.com/bigquery/docs/tables#create_an_empty_table_with_a_schema_definition) via Cloud Console as indicated in the documentation.

To create the Pub/Sub subscription in the console run:

```bash
gcloud pubsub subscriptions create dj_subscription_bq_direct --topic=dj-pubsub-topic --bigquery-table=$GCP_PROJECT:data_journey.pubsub_direct
```

## Validate ELT Pipeline implementation

You can now stream website interaction data points through your Cloud Run Proxy Service, Pub/Sub Topic & Subscription all the way up to your BigQuery destination table.

Run:

```bash
python3 synth_json_stream.py --endpoint=$ENDPOINT_URL --bucket=$BUCKET --file=$FILE
```

to direct an artificial click stream at your pipeline. If your datastream is still running from earlier you don't need to initiate it again.

After a minute or two you should find your BigQuery destination table populated with data points. The metrics of Pub/Sub topic and Subscription should also show the throughput. Take a specific look at the un-acknowledged message metrics in Pub/Sub. If everything works as expected it should be 0.

## Part 2: ETL(Extract Transform Load) - Cloud Run

ELT is a relatively new concept. Cheap availability of Data Warehouses allows efficient on-demand transformations. That saves storage and increases flexibility. All you have to manage are queries, not transformed datasets. And you can always go back to data in it's raw form.

Although, sometimes it just makes sense to apply transformation on incoming data directly. What if we need to apply some general cleaning, or would like to apply machine learning inference on the incoming data at the soonest point possible?

Traditional [ETL](https://cloud.google.com/bigquery/docs/migration/pipelines#etl) is a proven concept to do just that.

But ETL tools are maintenance overhead. In our example, you don't want to manage a Spark, GKE cluster or similar.Specifically, your requirement is a serverless and elastic ETL pipeline.

That means your pipeline should scale down to 0 when unused or up to whatever is needed to cope with a higher load.

To start off, let's reference the working directory:

```bash
cd ETL/CloudRun
```

## ETL Step 1

First component of our lightweight ETL pipeline is a BigQuery Table named `cloud_run`. The BigQuery Table should make use of the schema file `./schema.json`. The processing service will stream the transformed data into this table.

Run this command:

```bash
bq mk --location=europe-west1 --table $GCP_PROJECT:data_journey.cloud run ./schema.json
```

OR follow the documentation on how to [create a BigQuery table with schema through the console](https://cloud.google.com/bigquery/docs/tables#console).

## ETL Step 2

Second, let's set up your Cloud Run Processing Service. `./ETL/Cloud Run` contains all the necessary files.

Inspect the `Dockerfile` to understand how the container will be build.

`main.py` defines the web server that handles the incoming data points. Inspect `main.py` to understand the web server logic.

Make sure to replace the required variables in `config.py` so you can access them safely in `main.py`.

Once the code is completed build the container from `./ETL/Cloud Run` into a new [Container Repository](https://cloud.google.com/artifact-registry/docs/overview) named `data-processing-service`.

```bash
gcloud builds submit $RUN_PROCESSING_DIR --tag gcr.io/$GCP_PROJECT/data-processing-service
```

Validate the successful build with:

```bash
gcloud container images list
```

You should see something like:

```
NAME: gcr.io/<project-id>/pubsub-proxy
NAME: gcr.io/<project-id>/data-processing-service
Only listing images in gcr.io/<project-id>. Use --repository to list images in other repositories.
```

## ETL Step 3

Next step is to deploy a new cloud run processing service based on the container you just build to your Container Registry.

```bash
gcloud run deploy dj-run-service-data-processing --image gcr.io/$GCP_PROJECT/data-processing-service:latest --region=europe-west1 --allow-unauthenticated
```

## ETL Step 4

Define a Pub/Sub subscription named `dj-subscription_cloud_run` that can forward incoming messages to an endpoint.

You will need to create a Push Subscription to the Pub/Sub topic we already defined.

Enter the displayed URL of your processing in `./config_env.sh` as `PUSH_ENDPOINT` & reset the environment variables.

```bash
source config_env.sh
```

Create PubSub push subscription:

```bash
gcloud pubsub subscriptions create dj-subscription_cloud_run \
    --topic=dj-pubsub-topic \
    --push-endpoint=$PUSH_ENDPOINT
```

OR

read it can be [defined via the console](https://cloud.google.com/pubsub/docs/create-subscription#pubsub_create_push_subscription-console).

## Validate lightweight ETL pipeline implementation

You can now stream website interaction data points through your Cloud Run Proxy Service, Pub/Sub Topic & Subscription, Cloud Run Processing and all the way up to your BigQuery destination table.

Run:

```bash
python3 ./datalayer/synth_data_stream.py --endpoint=$ENDPOINT_URL
```
to direct an artificial click stream at your pipeline. No need to reinitialize if you still have the clickstream running from earlier.

After a minute or two you should find your BigQuery destination table populated with data points. The metrics of Pub/Sub topic and Subscription should also show the throughput. Take a specific look at the un-acknowledged message metrics in Pub/Sub. If everything works as expected it should be 0.

## Part 2: ETL(Extract Transform Load) - Dataflow

Cloud Run works smooth to apply simple data transformations. On top of that it scales to 0. So why not stop right there?

Let's think one step further. Imagine for example you need to apply aggregations, not only transformations. For example, you might need to support a real time dashboard to display the most active users made every minute (aggregation over multiple datapoints). Or you might want to apply real time ML inference of a demanding ML model (distributed compute) before data is written into your Data Warehouse.

For extremely latency sensitive applications, and cases in which aggregations or distributed compute make the transformations stateful neither ELT nor Cloud Run will do the job. This is where [Apache Beam](https://beam.apache.org/documentation/basics/) comes to shine!

Dataflow is a great tool to integrate into your pipeline for high volume data streams with complex transformations and aggregations. It is based on the open-source data processing framework Apache Beam.

For the challenges below let's reference the working directory:

```bash
cd ETL/Dataflow
```

## Challenge 1 (Dataflow)

First component of our dataflow ETL pipeline is a BigQuery Table named `dataflow`, and `data_journey` dataset if not previously created.

The BigQuery Table should make use of the schema file: `user_pseudo_id:STRING` and `event_count:INTEGER`.

The processing service will stream the transformed data into this table.

**Hint:** The [Big Query documentation](https://cloud.google.com/bigquery/docs/tables) might be helpful to follow.

<walkthrough-info-message>**The solution will be shown on the next page**</walkthrough-info-message>

Second component is the connection between Pub/Sub topic and Dataflow job.

Define a Pub/Sub subscription named `dj_subscription_dataflow` that can serve this purpose. You will define the actual dataflow job in the next step.

**Hint:** Read about [types of subscriptions](https://cloud.google.com/pubsub/docs/subscriber) and [how to create them](https://cloud.google.com/pubsub/docs/create-subscription#create_subscriptions).

<walkthrough-info-message>**The solution will be shown on the next page**</walkthrough-info-message>

## Challenge 1 (Dataflow) solution

Here is the solution for the previous page.

**BigQuery Table:**

```bash
bq --location=$GCP_REGION mk --dataset $GCP_PROJECT:data_journey
bq mk --location=$GCP_REGION --table $GCP_PROJECT:data_journey.dataflow user_pseudo_id:STRING,event_count:INTEGER
```

**Pub/Sub Subscription:**

You will need to create a Pull Subscription to the Pub/Sub topic we already defined. This is a fundamental difference to the Push subscriptions we encountered in the previous two examples. Dataflow will pull the data points from the queue independently, depending on worker capacity.

Use this command:

```bash
gcloud pubsub subscriptions create dj_subscription_dataflow --topic=dj-pubsub-topic
```

OR

read how it can be [defined via the console](https://cloud.google.com/pubsub/docs/create-subscription#pull_subscription).

## Challenge 2 (Dataflow)

Finally, all we are missing is your Dataflow job to apply transformations, aggregations and connect Pub/Sub queue with BigQuery Sink.

[Templates](https://cloud.google.com/dataflow/docs/concepts/dataflow-templates) let you create Dataflow jobs based on pre-existing code. That makes it quick to set up and reusable.

You need to apply custom aggregations on the incoming data. That means you need to create a dataflow job based on a [flex-template](https://cloud.google.com/dataflow/docs/guides/templates/using-flex-templates).

Find & examine the pipeline code in `.ETL/Dataflow/dataflow_processing.py`.

The pipeline is missing some code snippets. You will have to add three code snippets in `streaming_pipeline()`.

You need to design a pipeline that calculates number of events per user per 1 minute (they don't have to be unique). Ideally, we would like to see per one 1 hour, but for demonstration purposese we will shorten to 1 minute.

The aggregated values should be written into your BigQuery table.

Before you start coding replace the required variables in `config.py` so you can access them safely in `dataflow_processing.py`.


**Hint Read from PubSub Transform:** The [Python Documentation](https://beam.apache.org/releases/pydoc/current/apache_beam.io.gcp.pubsub.html) should help.

<walkthrough-info-message>**The solution will be shown on the next page**</walkthrough-info-message>


**Hint Data Windowing:** This is a challenging one. There are multiple ways of solving this. Easiest is a [FixedWindows](https://beam.apache.org/documentation/programming-guide/#using-single-global-window) with [AfterProcessingTime trigger](https://beam.apache.org/documentation/programming-guide/#event-time-triggers).

<walkthrough-info-message>**The solution will be shown on the next page**</walkthrough-info-message>


**Hint Counting the events per user:** Check out some [core beam transforms](https://beam.apache.org/documentation/programming-guide/#core-beam-transforms).

<walkthrough-info-message>**The solution will be shown on the next page**</walkthrough-info-message>

## Challenge 2 (Dataflow) solution

Here is the solution for the previous page.

**Read from PubSub Transform**

```
    json_message = (p
                    # Listining to Pub/Sub.
                    | "Read Topic" >> ReadFromPubSub(subscription=subscription)
                    # Parsing json from message string.
                    | "Parse json" >> beam.Map(json.loads))
```

**Data Windowing**

```
    fixed_windowed_items = (extract
                          | "CountEventsPerMinute" >> beam.WindowInto(beam.window.FixedWindows(60),
                                                                trigger=trigger.AfterWatermark(early=trigger.AfterProcessingTime(60), late=trigger.AfterCount(1)),
                                                                accumulation_mode=trigger.AccumulationMode.DISCARDING)
                       )
```

**Counting events per user**

```
    number_events =  (fixed_windowed_items | "Read" >> beam.Map(lambda x: (x["user_pseudo_id"], 1))
                                        | "Grouping users" >> beam.GroupByKey()
                                        | "Count" >> beam.CombineValues(sum)
                                        | "Map to dictionaries" >> beam.Map(lambda x: {"user_pseudo_id": x[0], "event_count": int(x[1])})) 
```

Before finishing this section make sure to update the project_id and region in `.ETL/Dataflow/config.py`.

## Challenge 3 (Dataflow)

To create a flex-template we first need to build the pipeline code as container in the Container Registry.

Build the Dataflow folder content as container named `beam-processing-flex-template` to your Container Registry.

<walkthrough-info-message>**The solution will be shown on the next page**</walkthrough-info-message>

Create a Cloud Storage Bucket named `gs://<project-id>-gaming-events`. Create a Dataflow flex-template based on the built container and place it in your new GCS bucket.

**Hint:** Checkout the [docs](https://cloud.google.com/sdk/gcloud/reference/dataflow/flex-template/build) on how to build a dataflow flex-template.

<walkthrough-info-message>**The solution will be shown on the next page**</walkthrough-info-message>

## Challenge 3 (Dataflow) solution

Here is the solution for the previous page.

**Dataflow folder content to Container Registry**

```bash
gcloud builds submit --tag gcr.io/$GCP_PROJECT/beam-processing-flex-template
```

**Dataflow flex template**

Create a new bucket by running:

```bash
gsutil mb -c standard -l europe-west1 gs://$GCP_PROJECT-gaming-events
```

Build the flex-template into your bucket using:

```bash
gcloud dataflow flex-template build gs://$GCP_PROJECT-gaming-events/df_templates/dataflow_template.json --image=gcr.io/$GCP_PROJECT/beam-processing-flex-template --sdk-language=PYTHON
```

## Challenge 4 (Dataflow)

Run a Dataflow job based on the flex-template you just created.

The job creation will take 5-10 minutes.

**Hint:** The [documentation on the flex-template run command](https://cloud.google.com/sdk/gcloud/reference/dataflow/flex-template/run) should help.

<walkthrough-info-message>**The solution will be shown on the next page**</walkthrough-info-message>

## Challenge 4 (Dataflow) solution

Here is the solution for the previous page.

```bash
gcloud dataflow flex-template run dataflow-job --template-file-gcs-location=gs://$GCP_PROJECT-gaming-events/df_templates/dataflow_template.json --region=europe-west1 --service-account-email="data-journey-pipeline@$GCP_PROJECT.iam.gserviceaccount.com" --max-workers=1 --network=terraform-network
```

## Validate Dataflow ETL pipeline implementation

You can now stream website interaction data points through your Cloud Run Proxy Service, Pub/Sub Topic & Subscription, Dataflow job and all the way up to your BigQuery destination table.

Run:

```bash
python3 synth_json_stream.py --endpoint=$ENDPOINT_URL --bucket=$BUCKET --file=$FILE
```

to direct an artificial click stream at your pipeline. No need to reinitialize if you still have the clickstream running from earlier.

After a minute or two you should find your BigQuery destination table populated with data points. The metrics of Pub/Sub topic and Subscription should also show the throughput. Take a specific look at the un-acknowledged message metrics in Pub/Sub. If everything works as expected it should be 0.

## Part 2.1: Extract Load Transform (ELT)

In comparison to ETL there also exists a process called ELT. This can be used if the e.g. the transformations to be done on the data are not as memory critical and could be done after loading the data into the destination format & location.

If you want to explore this further we have curated some code in the following [repository](https://github.com/NucleusEngineering/data-journey/tree/tutorial/ELT).

Otherwise you can skip this part and continue on the next page.

## Part 3: Change Data Capture (CDC)

Datastream is a serverless and easy-to-use Change Data Capture (CDC) and replication service that allows you to synchronize data across heterogeneous databases, storage systems, and applications reliably and with minimal latency. In this lab you’ll learn how to replicate data changes from your OLTP workloads into BigQuery, in real time.

In this hands-on lab you’ll deploy the below mentioned resources all at once via terrafrom or individually. Then, you will create and start a Datastream stream for replication and CDC.

What you’ll do:

* Prepare a MySQL Cloud SQL instance
* Create a Cloud Storage bucket
* Import data into the Cloud SQL instance
* Create a Datastream connection profile referencing MySQL DB as source profile
* Create a Datastream connection profile referencing BigQuery as destination profile
* Create a Datastream stream and start replication
* Write Inserts and Updates
* Verify updates in BigQuery

[Here is an image of an exemplary Datastream pipeline](https://github.com/NucleusEngineering/data-journey/blob/tutorial/CDC/datastream-preview.png). 

### Git clone repo

```bash
git clone https://github.com/NucleusEngineering/data-journey.git
cd data-journey/CDC
```

## Set up cloud environment

Initilize your account and project

<walkthrough-info-message>If you are using the Google Cloud Shell you can skip this step of initalization. Continue with setting the project.</walkthrough-info-message>

```bash
gcloud init
```

Set Google Cloud Project

```bash
export project_id=<your-project-id>
gcloud config set project $project_id
```

Check Google Cloud Project config set correctly

```bash
gcloud config list
```

Set compute zone

```bash
gcloud config set compute/zone us-central1-f
```

## Deploy using Terraform

Use Terraform to deploy the following services and networking resources defined in the `main.tf` file

* Cloud SQL
* Cloud Storage

### Install Terraform 

If you are using the Google Cloud Shell Terraform is already installed.

Follow the instructions to [install the Terraform cli](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli?in=terraform%2Fgcp-get-started).

This repo has been tested on Terraform version `1.2.6` and the Google provider version `4.31.0`.

### Update Project ID in terraform.tfvars

Rename the `terraform.tfvars.example` file to `terraform.tfvars` and update the default project ID in the file to match your project ID.

Check that the file has been saved with the updated project ID value.

```bash
cat terraform.tfvars
```

### Initialize Terraform

```bash
terraform init
```

### Create resources in Google Cloud

Run the plan cmd to see what resources will be greated in your project.

<walkthrough-info-message>**Important:** Make sure you have updated the Project ID in `terraform.tfvars` before running this.</walkthrough-info-message>

```bash
terraform plan
```

Run the apply cmd and point to your `.tfvars` file to deploy all the resources in your project.

```bash
terraform apply -var-file terraform.tfvars
```

This will show you a plan of everything that will be created.

<walkthrough-info-message>When prompted, you should enter `yes` to proceed.</walkthrough-info-message>

### Terraform output

Once everything has succesfully run you should see the following output:

```
google_compute_network.vpc_network: Creating...
.
.
.
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

## Import a SQL file into MySQL

Next, you will copy the `create_mysql.sql` file below into the Cloud Storage bucket you created above, make the file accessible to your Cloud SQL service account, and import the SQL command into your database.

```
CREATE DATABASE IF NOT EXISTS database_datajourney;
USE database_datajourney;

CREATE TABLE IF NOT EXISTS database_datajourney.example_table (
event_timestamp integer,
event_name varchar(255),
user_pseudo_id varchar(255)
);

INSERT INTO database_datajourney.example_table (event_timestamp, event_name, user_pseudo_id) VALUES
(153861, 'level_complete_quickplay', 'D50D60807F5347EB64EF0CD5A3D4C4CD'),
(153862,'screen_view', 'D50D60807F5347EB64EF0CD5A3D4C4CD'),
(153863, 'post_score', '2D50D60807F5347EB64EF0CD5A3D4C4CD');
```

```bash
SERVICE_ACCOUNT=$(gcloud sql instances describe mysql | grep serviceAccountEmailAddress | awk '{print $2;}')

gsutil cp create_mysql.sql gs://${project_id}/resources/create_mysql.sql
gsutil iam ch serviceAccount:${SERVICE_ACCOUNT}:objectViewer gs://${project_id}

gcloud sql import sql mysql gs://${project_id}/resources/create_mysql.sql --quiet
```

## Create Datastream resources

In the Cloud Console UO, navigate to Datastream then click Enable to enable the Datastream AP.

Create two connection profiles, one for the MySQL source, and another for the BigQuery destination.

My SQL connection profile:

* The IP and port of the Cloud SQL for MySQL instance created earlier
* username: `root`, password: `password123`
* encryption: none
* connectivity method: IP allowlisting BigQuery connection profile:
* connection profile ID

Create stream by selecting MyQL and BigQuery connection profiles, and make sure to mark the tables you want to replicate (we will only replicate the datastream-datajourney database), and finally run validation, and create and start the stream.

## View the data in BiqQuery

View these tables in the BigQuery UI.

### Write Inserts and Updates

Next, you will copy `update_mysql.sql` file below into the Cloud Storage bucket you created above, make the file accessible to your Cloud SQL service account, and import the SQL command into your database.

```
CREATE DATABASE IF NOT EXISTS database_datajourney;
USE database_datajourney;

CREATE TABLE IF NOT EXISTS database_datajourney.example_table (
event_timestamp integer,
event_name varchar(255),
user_pseudo_id varchar(255)
);

INSERT INTO database_datajourney.example_table (event_timestamp, event_name, user_pseudo_id) VALUES
(153864, 'level_complete_quickplay', 'D50D60807F5347EB64EF0CD5A3D4C4CD'),
(153865, 'level_start_quickplay', 'D50D60807F5347EB64EF0CD5A3D4C4CD'),
(153866, 'level_fail_quickplay', 'D50D60807F5347EB64EF0CD5A3D4C4CD'),
(153867, 'session_start', 'D50D60807F5347EB64EF0CD5A3D4C4CD'),
(153868, 'user_engagement', 'D50D60807F5347EB64EF0CD5A3D4C4CD');
```

```bash
SQL_FILE=update_mysql.sql
SERVICE_ACCOUNT=$(gcloud sql  describe mysql | grep serviceAccountEmailAddress | awk '{print $2;}')

gsutil cp ${SQL_FILE} gs://${project_id}/resources/${SQL_FILE}
gsutil iam ch serviceAccount:${SERVICE_ACCOUNT}:objectViewer gs://${project_id}

gcloud sql import sql mysql gs://${project_id}/resources/${SQL_FILE} --quiet
```

## Verify updates in BigQuery

Run the query below to verify data changes in BiqQuery:

```
SELECT
 *
FROM
 `<project_id>.database_datajourney.example_table`
LIMIT
 100
```

## Terraform Destroy

Use Terraform to destroy all resources

```bash
terraform destroy
```

## Machine Learning Datathon

Now that we learned how to ingest data into BigQuery from PubSub Messages and transform them via ETL, let's continue with the [next step in the end-to-end data journey](https://github.com/NucleusEngineering/data-journey/blob/main/rsc/architecture.png): Getting insights from data via Machine Learning.

User retention can be a major challenge across industries. To retain a larger percentage of users after their first use of an app, developers can take steps to motivate and incentivize certain users to return. But to do so, developers need to identify the propensity of any specific user returning after the first 24 hours. In this hackathon, we will discuss how you can use BigQuery ML to run propensity models on Google Analytics 4 data from an example gaming app data to determine the likelihood of specific users returning to your app.

See the following architecture for our ML Datathon.

We created 5 Labs (Notebooks) to guide you through this journey.

### Lab 1

* Pre-process the raw event data in views
* Identify users & the label feature
* Process demographic features
* Process behavioral features
* Create the training and evaluation sets

### Lab 2

* Data exploration on the training set
* Train your classification models using BQML
* Perform feature engineering using TRANSFORM in BQML
* Evaluate the model using BQML
* Make predictions using BQML

### Lab 3

* Export and register our trained BQML model to Vertex AI Model Registry (e.g tensorflow format)
* Deploy our registered model to a new endpoint
* Deploy another updated model to the same endpoint (traffic split 50%)
* Enable Prediction data drift in our endpoint for submitting a skewed payload

### Lab 4

* Orchestrate Lab 2 and Lab 3 using Vertex Pipelines

### Lab 5

* Experience GenAI features within BigQuery

You can access all of our labs on our [Github](https://github.com/NucleusEngineering/data-journey/tree/main/ML). After downloading the different lab files you can upload and run them in for example our **VertexAI Colab Enterperise** Notebook environment.

**Have fun!**