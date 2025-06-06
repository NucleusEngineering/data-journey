<walkthrough-metadata>
  <meta name="title" content="Welcome to Cloud Native Data Journey with Google Cloud!" />
  <meta name="description" content="This walkthrough describes how to build an end-to-end data pipeline, from collection, over transformation and up to activation of the data." />
  <meta name="keywords" content="data,bigquery,dataflow,cloudrun,etl,elt" />
  <meta name="component_id" content="1163696" />
</walkthrough-metadata>

# Cloud Native Data Journey on Google Cloud

This walkthrough describes how to build an end-to-end data pipeline, from collection, over transformation and up to activation of the data.

We will be using raw event data from a real mobile gaming app called Flood It, that originates from Google Analytics for Firebase.

Events provide insight on what is happening in an app or on a website, such as user actions, system events, or errors.

Every row in the dataset is an event, with various characteristics relevant to that event stored in a nested format within the row.

While Google Analytics logs many types of events already by default, developers can also customize the types of events they also wish to log.

User retention can be a major challenge for mobile game developers.

The goal of this workshop is to develop an ML propensity model to determine the likelihood of users returning to your app.

[Click here to see an image from the architecture we'll be about to use.](https://github.com/NucleusEngineering/data-journey/blob/main/rsc/architecture.png)

By the end of this workshop, you will learn how to:

**Ingestion**
* Stream the raw event data into messaging queue **(/Data-Simulator)**
* Synchronize the data in MySQL and BigQuery **(/CDC)**

**Transformation**
* Transform the data using different transformation tools **(/ETL)**
* Transform the data once it is loaded into BigQuery **(/ELT)**

**Activation**
* Train ML model Using BigQueryML and automate your ML workflow using Vertex ML Pipelines **(/ML)**



## Working with labs



You can insert commands into the terminal using the following button on top of each code line in the tutorial:
<walkthrough-cloud-shell-icon></walkthrough-cloud-shell-icon>. The button will automatically open the terminal.
Please make sure you are using the terminal of the IDE & not the regular terminal. (Cloud Shell Editor (grey background is the correct one))

Let's try:

```bash
echo "I'm ready to get started."
```

Execute by pressing the return key in the terminal that has been opened in the lower part of your screen.
Now let's setup project ID:
```bash
cd ~
gcloud config set project [PROJECT_ID]
```
You can find the Project ID in Cloud Console, if you click on the project name. (Top left on the screen, right next to "Google Cloud" logo)

### Enable services

First, we need to enable some Google Cloud Platform (GCP) services. Enabling GCP services is necessary to access and use the resources and capabilities associated with those services. Each GCP service provides a specific set of features for managing cloud infrastructure, data, AI models, and more. Enabling them takes a few minutes.

<walkthrough-enable-apis apis=
  "storage-component.googleapis.com,
  run.googleapis.com,
  dataflow.googleapis.com,
  notebooks.googleapis.com,
  serviceusage.googleapis.com,
  cloudresourcemanager.googleapis.com,
  pubsub.googleapis.com,
  compute.googleapis.com,
  metastore.googleapis.com,
  datacatalog.googleapis.com,
  bigquery.googleapis.com,
  dataplex.googleapis.com,
  datalineage.googleapis.com,
  dataform.googleapis.com,
  dataproc.googleapis.com,
  bigqueryconnection.googleapis.com,
  aiplatform.googleapis.com,
  cloudbuild.googleapis.com,
  cloudaicompanion.googleapis.com,
  artifactregistry.googleapis.com">
</walkthrough-enable-apis>

Internal: check Organizational Policies for Argolis envirnoments.
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

To get started, click **Start**

 ##  Environment Setup

<walkthrough-tutorial-duration duration="15"></walkthrough-tutorial-duration>
<walkthrough-tutorial-difficulty difficulty="2"></walkthrough-tutorial-difficulty>

Let's build the first step in the Data Journey.
In this lab we will set up your environment and set up a messaging stream for our data.

We have to make sure your GCP project is prepared.
You should already have cloned the gitub repo. Let's move to the correct folder to start the walkthrough.

```bash
cd ~
cd data-journey/Data-Simulator
```

We will be using Terraform to provision infrastructure and resources, setup Network, Service Account and Permissions. 
In addition, we will extract a sample dataset from a public BigQuery table, build and deploy a sample app and create a Pub/Sub topic.

Want to know what exactly the Terraform configuration file does?

Let's ask Gemini:

1. Open  <walkthrough-editor-open-file filePath="home/admin_/data-journey/Data-Simulator/main.tf">`main.tf`</walkthrough-editor-open-file>.
2. Open Gemini Code Assist <img style="vertical-align:middle" src="https://www.gstatic.com/images/branding/productlogos/gemini/v4/web-24dp/logo_gemini_color_1x_web_24dp.png" width="8px" height="8px"> on the left hand side. (**Important**: click on the Gemini star, which is smaller and embedded in the Editor. **Don't** click on the bigger Gemini star at the very top (right of the search bar))
3. Insert ``What does the main.tf file do?`` into the Gemini prompt.


First, we need to change the terraform variable file. You can open files directly from this tutorial:
Open `terraform.tfvars` <walkthrough-editor-open-file filePath="/home/admin_/data-journey/Data-Simulator/terraform.tfvars">by clicking here</walkthrough-editor-open-file> and add your own project id.

❗ Please do not include any whitespaces when setting these variables.

Build the basic permissions & networking setup via terraform apply.

```bash
terraform init -upgrade
```

```bash
terraform apply -var-file terraform.tfvars
```

 ### Validate Event Ingestion

After a few minutes, we should have the proxy container up and running. We can check and copy the endpoint URL by running:

```bash
gcloud run services list 
```

The endpoint URL refers to the URL of the proxy container deployed to Cloud Run with the streaming data input. 

We need to add GCP Project ID, the GCP Region (europe-west1) and the endpoint URL in `./config_env.sh`<walkthrough-editor-open-file filePath="/home/admin_/data-journey/Data-Simulator/config_env.sh">by clicking here</walkthrough-editor-open-file>.


First, enter the variables in the config file. You can open it <walkthrough-editor-open-file filePath="/home/admin_/data-journey/Data-Simulator/config_env.sh">
in the Cloud Shell Editor</walkthrough-editor-open-file> to read or edit it.

Set all necessary environment variables by running:

```bash
source config_env.sh
```
### ❗ In case you accidentally close the tutorial or the editor, or the session expires you can resume by running the following commands: 

```bash
cd ~/data-journey/Data-Simulator/
source config_env.sh
```

You can now stream website interaction data points through a Cloud Run Proxy Service into your Pub/Sub Topic.

The script `synth_json_stream.py` contains everything you need to simulate a stream. Run to direct an artificial click stream at your pipeline.

```bash
python3 synth_json_stream.py --endpoint=$ENDPOINT_URL --bucket=$BUCKET --file=$FILE
```

After a minute or two validate that your solution is working by inspecting the [metrics](https://cloud.google.com/pubsub/docs/monitor-topic) of your Pub/Sub topic. Of course the topic does not have any consumers yet. Thus, you should find that messages are queuing up.

By default you should see around .5 messages per second streaming into the topic.

**Now you can stop the stream with "Ctrl+C" in the Cloud Shell.**




 ## Lab 1: Data ingestion

<walkthrough-tutorial-duration duration="20"></walkthrough-tutorial-duration>
<walkthrough-tutorial-difficulty difficulty="2"></walkthrough-tutorial-difficulty>


Now that your data ingestion is working correctly we move on to set up your processing infrastructure. Data processing infrastructures often have vastly diverse technical and business requirements. We will find the right setup for three completely different settings.

[ELT is in!](https://cloud.google.com/bigquery/docs/migration/pipelines#elt) Imagine you don't actually want to set up processing. Instead, you would like to build [a modern Lakehouse structure](https://cloud.google.com/blog/products/data-analytics/open-data-lakehouse-on-google-cloud) with ELT processing. Therefore, your main concern at this point is to bring the incoming raw data into your Data Warehouse as cost-efficient as possible. Data users will worry about the processing.

To start out we aim for rapid iteration. We plan using BigQuery as Data Lakehouse - Combining Data Warehouse and Data Lake.


### Bring raw data to BigQuery (EL) - Pub/Sub BigQuery


To implement our lean EL pipeline we need:

* BigQuery Dataset
* BigQuery Table
* Pub/Sub BigQuery Subscription

Pub/Sub enables real-time streaming into BigQuery. Learn more about [Pub/Sub integrations with BigQuery](https://cloud.google.com/pubsub/docs/bigquery).

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
gcloud pubsub subscriptions create dj_subscription_bq_direct --topic=dj-pubsub-topic --bigquery-table=$GCP_PROJECT:data_journey.pubsub_direct --project=$GCP_PROJECT
```

### Validate EL Pipeline implementation

You can now stream website interaction data points through your Cloud Run Proxy Service, Pub/Sub Topic & Subscription all the way up to your BigQuery destination table.

Run:

```bash
python3 synth_json_stream.py --endpoint=$ENDPOINT_URL --bucket=$BUCKET --file=$FILE
```

to direct an artificial click stream at your pipeline. If your datastream is still running from earlier you don't need to initiate it again.

After a minute or two you should find your BigQuery destination table populated with data points. The metrics of Pub/Sub topic and Subscription should also show the throughput. Take a specific look at the un-acknowledged message metrics in Pub/Sub. If everything works as expected it should be 0.

## (Optional) Lab 2: Change Data Capture Ingestion (CDC)

<walkthrough-tutorial-duration duration="15"></walkthrough-tutorial-duration>
<walkthrough-tutorial-difficulty difficulty="2"></walkthrough-tutorial-difficulty>


Datastream is a serverless and easy-to-use Change Data Capture (CDC) and replication service that allows you to synchronize data across heterogeneous databases, storage systems, and applications reliably and with minimal latency. In this lab you’ll learn how to replicate data changes from your OLTP workloads into BigQuery, in real time.

This hands-on lab will guide you through deploying the resources mentioned below, either all at once via Terraform or separately. You will then proceed to create and start a Datastream stream for replication and CDC (Change Data Capture).

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

Clone the `https://github.com/NucleusEngineering/data-journey.git` repo, **if not already done so**. Otherwise just `cd` into the `CDC` folder.

```bash
cd ~/data-journey/CDC
```

### Set up cloud environment

Initialize your account and project

<walkthrough-info-message>If you are using the Google Cloud Shell you can skip this step of initalization. Continue with setting the project.</walkthrough-info-message>

```bash
gcloud init
```

Set Google Cloud Project, if not already done so.

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
gcloud config set compute/zone europe-west1
```

### Deploy using Terraform

Use Terraform to deploy the following services and networking resources defined in the `main.tf` file

* Cloud SQL
* Cloud Storage

### Install Terraform 

If you are using the Google Cloud Shell Terraform is already installed.

Follow the instructions to [install the Terraform cli](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli?in=terraform%2Fgcp-get-started).

This repo has been tested on Terraform version `1.2.6` and the Google provider version `4.31.0`.

### Update Project ID in terraform.tfvars

In the `terraform.tfvars` file , update the default project ID to match your project ID.

Check that the file has been saved with the updated project ID value.

```bash
cat terraform.tfvars
```

### Initialize Terraform

```bash
terraform init
```

### Create resources in Google Cloud

Run the plan cmd to see what resources will be created in your project.

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

### Import a SQL file into MySQL

Next, you will copy the `create_mysql.sql` file below into the Cloud Storage bucket you created above, make the file accessible to your Cloud SQL service account, and import the SQL command into your database.

**Note: The content of the SQL file is just here for informational purposes. Continue with the terminal commands below.**

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
```

```bash

gsutil cp create_mysql.sql gs://${GCP_PROJECT}/resources/create_mysql.sql
```
```bash
gsutil iam ch serviceAccount:${SERVICE_ACCOUNT}:objectViewer gs://${GCP_PROJECT}
```
```bash

gcloud sql import sql mysql gs://${GCP_PROJECT}/resources/create_mysql.sql --quiet
```

### Create Datastream resources

In the Cloud Console UI, navigate to Datastream then click Enable to enable the Datastream API.

Create two connection profiles, one for the MySQL source, and another for the BigQuery destination.

My SQL connection profile:

* The IP and port of the Cloud SQL for MySQL instance created earlier
* username: `root`, password: `password123`
* encryption: none
* connectivity method: IP allowlisting
* region: eu-west1

BigQuery connection profile:
* connection profile ID

Create stream by selecting MyQL and BigQuery connection profiles **(also make sure it runs in the eu and not us region)**, and make sure to mark the tables you want to replicate (we will only replicate the database_datajourney database), and finally run validation, then create and start the stream.

### View the data in BiqQuery

View these tables in the BigQuery UI.

### Write Inserts and Updates

Next, you will copy `update_mysql.sql` file below into the Cloud Storage bucket you created above, make the file accessible to your Cloud SQL service account, and import the SQL command into your database.

**Note: The content of the SQL file is just here for informational purposes. Continue with the terminal commands below.**

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
```
```bash
SERVICE_ACCOUNT=$(gcloud sql instances describe mysql | grep serviceAccountEmailAddress | awk '{print $2;}') 
```

```bash

gsutil cp ${SQL_FILE} gs://${GCP_PROJECT}/resources/${SQL_FILE}
```

```bash
gsutil iam ch serviceAccount:${SERVICE_ACCOUNT}:objectViewer gs://${GCP_PROJECT}
```

```bash 

gcloud sql import sql mysql gs://${GCP_PROJECT}/resources/${SQL_FILE} --quiet
```

### Verify updates in BigQuery

Run the query below to verify data changes in BiqQuery. Change your project ID:

```
SELECT
 *
FROM
 `<project_id>.database_datajourney.example_table`
LIMIT
 100
```

## Lab 3: ETL (Extract Transform Load) - Cloud Run

<walkthrough-tutorial-duration duration="25"></walkthrough-tutorial-duration>
<walkthrough-tutorial-difficulty difficulty="3"></walkthrough-tutorial-difficulty>


ELT is a relatively new concept. Cheap availability of Data Warehouses allows efficient on-demand transformations. That saves storage and increases flexibility. All you have to manage are queries, not transformed datasets. And you can always go back to data in it's raw form.

Although, sometimes it just makes sense to apply transformation on incoming data directly. What if we need to apply some general cleaning, or would like to apply machine learning inference on the incoming data at the soonest point possible?

Traditional [ETL](https://cloud.google.com/bigquery/docs/migration/pipelines#etl) is a proven concept to do just that.

But ETL tools are maintenance overhead. In our example, you don't want to manage a Spark, GKE cluster or similar.Specifically, your requirement is a serverless and elastic ETL pipeline.

That means your pipeline should scale down to 0 when unused or up to whatever is needed to cope with a higher load.

To start off, let's reference the working directory:

```bash
cd ~/data-journey/ETL/CloudRun
```

### ETL - Step 1

First component of our lightweight ETL pipeline is a BigQuery Table named `cloud_run`. The BigQuery Table should make use of the schema file `./schema.json`. The processing service will stream the transformed data into this table.

Run this command:

```bash
bq mk --location=europe-west1 --table $GCP_PROJECT:data_journey.cloud_run ./schema.json
```

OR follow the documentation on how to [create a BigQuery table with schema through the console](https://cloud.google.com/bigquery/docs/tables#console).

### ETL - Step 2

Second, let's set up your Cloud Run Processing Service. `./ETL/CloudRun` contains all the necessary files.

Inspect the `Dockerfile` to understand how the container will be build.

`main.py`  in the `data-journey/ETL/CloudRun` folder defines the web server that handles the incoming data points. Inspect `main.py` to understand the web server logic. 

We can use Gemini Code Assist:

1. Open Gemini Code Assist <img style="vertical-align:middle" src="https://www.gstatic.com/images/branding/productlogos/gemini/v4/web-24dp/logo_gemini_color_1x_web_24dp.png" width="8px" height="8px"> on the left hand side.
2. Select the `main.py` file in the Explorer of the `data-journey/ETL/CloudRun` folder.
3. Insert ``Please explain what the main.py file does?`` into the Gemini prompt.

Make sure to replace the required PROJECT_ID in `config.py` in the `./CloudRun` folder so you can access them safely in `main.py`.

Open `~/data-journey/ETL/CloudRun/config.py` <walkthrough-editor-open-file filePath="/home/admin_/data-journey/ETL/CloudRun/config.py">by clicking here</walkthrough-editor-open-file> and add your own variables.

Open `~/data-journey/Data-Simulator/config_env.sh` <walkthrough-editor-open-file filePath="/home/admin_/data-journey/Data-Simulator/config_env.sh">by clicking here</walkthrough-editor-open-file> uncomment RUN_PROCESSING_DIR and save this variable.

Once the code is completed build the container from `./ETL/Cloud Run` into a new [Container Repository](https://cloud.google.com/artifact-registry/docs/overview) named `data-processing-service`.


```bash
docker build -t eu.gcr.io/$GCP_PROJECT/data-processing-service .
```
```bash
gcloud auth configure-docker
```
```bash
docker push eu.gcr.io/$GCP_PROJECT/data-processing-service
```


Validate the successful build with:

```bash
gcloud container images list --repository=eu.gcr.io/$GCP_PROJECT

```

You should see something like:

```
NAME: eu.gcr.io/<project-id>/pubsub-proxy
NAME: eu.gcr.io/<project-id>/data-processing-service
Only listing images in gcr.io/<project-id>. Use --repository to list images in other repositories.
```

### ETL - Step 3

Next step is to deploy a new cloud run processing service based on the container you just build to your Container Registry.

```bash
gcloud run deploy dj-run-service-data-processing --image eu.gcr.io/$GCP_PROJECT/data-processing-service:latest --region=europe-west1 --allow-unauthenticated
```

### ETL - Step 4

Define a Pub/Sub subscription named `dj-subscription_cloud_run` that can forward incoming messages to an endpoint.

You will need to create a Push Subscription to the Pub/Sub topic we already defined.

Enter the displayed URL of your processing in `./config_env.sh` as `PUSH_ENDPOINT` & export that variable in the shell.
Open `~/data-journey/Data-Simulator/config_env.sh` <walkthrough-editor-open-file filePath="/home/admin_/data-journey/Data-Simulator/config_env.sh">by clicking here</walkthrough-editor-open-file> and add your PUSH_ENDPOINT.

```bash
export PUSH_ENDPOINT="<your-push-endpoint-URL>"
```

Create PubSub push subscription:

```bash
gcloud pubsub subscriptions create dj-subscription_cloud_run \
    --topic=dj-pubsub-topic \
    --push-endpoint=$PUSH_ENDPOINT
```

OR read here: [defined via the console](https://cloud.google.com/pubsub/docs/create-subscription#pubsub_create_push_subscription-console).



### Validate lightweight ETL pipeline implementation


You can now stream website interaction data points through your Cloud Run Proxy Service, Pub/Sub Topic & Subscription, Cloud Run Processing and all the way up to your BigQuery destination table.

Run:

```bash
cd ~
cd data-journey/Data-Simulator
```

```bash
python3 synth_json_stream.py --endpoint=$ENDPOINT_URL --bucket=$BUCKET --file=$FILE
```
to direct an artificial click stream at your pipeline. No need to reinitialize if you still have the clickstream running from earlier.

After a minute or two you should find your BigQuery destination table populated with data points. The metrics of Pub/Sub topic and Subscription should also show the throughput. Take a specific look at the un-acknowledged message metrics in Pub/Sub. If everything works as expected it should be 0.


## Lab 4: ELT (Extract Load Transform) - Dataform

<walkthrough-tutorial-duration duration="30"></walkthrough-tutorial-duration>
<walkthrough-tutorial-difficulty difficulty="3"></walkthrough-tutorial-difficulty>


In comparison to ETL, there's also a process called ELT. ELT can be used if the data transformations are not as memory critical and can be performed after loading the data into the target system and location.


During this lab, you gather consolidate views on:
* **Returning Users**
This view aggregates the first and the last engagement of by user and defines a churned user: Churned -> If last activity was within 24h of sign up

* **User Demographics**
This view extracts some demographic data from the user that has been collected by Google Analytics; E.g. country, device/OS, language

* **User Behaviour**
This view aggregates KPIs that describe the user behaviour. E.g.  count of completed levels, sum of scores, # of challenges to a friend

  
### Dataform 

Dataform is a fully managed service that helps data teams build, version control, and orchestrate SQL workflows in BigQuery. It provides an end-to-end experience for data transformation, including:

* Table definition: Dataform provides a central repository for managing table definitions, column descriptions, and data quality assertions. This makes it easy to keep track of your data schema and ensure that your data is consistent and reliable.  
* Dependency management: Dataform automatically manages the dependencies between your tables, ensuring that they are always processed in the correct order. This simplifies the development and maintenance of complex data pipelines.  
* Orchestration: Dataform orchestrates the execution of your SQL workflows, taking care of all the operational overhead. This frees you up to focus on developing and refining your data pipelines.

Dataform is built on top of Dataform Core, an open source SQL-based language for managing data transformations. Dataform Core provides a variety of features that make it easy to develop and maintain data pipelines, including:

* Incremental updates: Dataform Core can incrementally update your tables, only processing the data that has changed since the last update. 
* Slowly changing dimensions: Dataform Core provides built-in support for slowly changing dimensions, which are a common type of data in data warehouses.   
* Reusable code: Dataform Core allows you to write reusable code in JavaScript, which can be used to implement complex data transformations and workflows.

Dataform is integrated with a variety of other Google Cloud services, including GitHub, GitLab, Cloud Composer, and Workflows. This makes it easy to integrate Dataform with your existing development and orchestration workflows.  

### Use Cases for Dataform

Dataform can be used for a variety of use cases, including:

* Data Warehousing: Dataform can be used to build and maintain data warehouses that are scalable and reliable.  
* Data Engineering: Dataform can be used to develop and maintain data pipelines that transform and load data into data warehouses.  
* Data Analytics: Dataform can be used to develop and maintain data pipelines that prepare data for analysis.  
* Machine Learning: Dataform can be used to develop and maintain data pipelines that prepare data for machine learning models.

***


### Create a Dataform Pipeline

First step in implementing a pipeline in Dataform is to set up a repository and a development environment. Detailed quickstart and instructions can be found [here](https://cloud.google.com/dataform/docs/quickstart-create-workflow).

### Create a Repository in Dataform

Go to [Dataform](https://console.cloud.google.com/bigquery/dataform) (part of the BigQuery console).

First let's make sure we have the Project number in a var:

<walkthrough-info-message>**Important:** Project number is NOT the project ID that we saved before. Therefore DO NOT skip this step. </walkthrough-info-message>
```bash
gcloud auth login
```
```bash
export PROJECT_NUMBER=$(gcloud projects describe "$GCP_PROJECT" --format="value(projectNumber)")
```
Now, let's follow the steps:

1. Click on <walkthrough-spotlight-pointer locator="css(a[id$=create-repository])">CREATE REPOSITORY</walkthrough-spotlight-pointer>

2. Use the following values when creating the repository:

    Repository ID: `datajourney-repository` \
    Region: `us-central1` \
    Service Account: `Default Dataform service account`

3. And click on <walkthrough-spotlight-pointer locator="text('create')">CREATE</walkthrough-spotlight-pointer>
```bash
export DATAFORM_SA="service-${PROJECT_NUMBER}@gcp-sa-dataform.iam.gserviceaccount.com"
```
The dataform service account you see on your screen should be `{{ DATAFORM_SA }}`. We will need it later.


Next, click <walkthrough-spotlight-pointer locator="text('go to repositories')">GO TO REPOSITORIES</walkthrough-spotlight-pointer>, and then choose the <walkthrough-spotlight-pointer locator="text('datajourney-repository')">datajourney-repository</walkthrough-spotlight-pointer> you just created.



### Create a Dataform Workspace

You should now be in the <walkthrough-spotlight-pointer locator="text('development workspaces')">Development workspaces</walkthrough-spotlight-pointer> tab of the hackathon-repository page.

First, click <walkthrough-spotlight-pointer locator="text('create development workspace')">Create development workspace</walkthrough-spotlight-pointer> to create a copy of your own repository.  You can create, edit, or delete content in your repository without affecting others.


In the **Create development workspace** window, do the following:  
   1. In the <walkthrough-spotlight-pointer locator="semantic({textbox 'Workspace ID'})">Workspace ID</walkthrough-spotlight-pointer> field, enter `datajourney-workspace`.

   2. Click <walkthrough-spotlight-pointer locator="text('create')">CREATE</walkthrough-spotlight-pointer>
   3. The development workspace page appears.  
   4. Click on the newly created `datajourney-workspace` 
   5. Click <walkthrough-spotlight-pointer locator="css(button[id$=initialize-workspace-button])">Initialize workspace</walkthrough-spotlight-pointer>

### Adjust workflow settings

We will now set up our custom workflow.

1. Edit the `workflow_settings.yaml`file (if needed):

2. Replace `defaultDataset` value with ``dataform``

3. Make sure `defaultProject` value is ``{{ PROJECT_ID }}``

4. add the lines: (put notice to add a line-break after `vars:`, keep the created indentation of the second line.)
`vars:
    ml_models_dataset: <your-project-id>.outputs`

5. Click on <walkthrough-spotlight-pointer locator="text('install packages')">INSTALL PACKAGES</walkthrough-spotlight-pointer> ***only once***. You should see a message at the bottom of the page:

    *Package installation succeeded*

Next, let's create several workflow files and directories:

1. Delete the following files from the <walkthrough-spotlight-pointer locator="semantic({treeitem 'Toggle node *definitions more'})">*definitions</walkthrough-spotlight-pointer> folder:

    `first_view.sqlx`
    `second_view.sqlx`

2. Within <walkthrough-spotlight-pointer locator="semantic({treeitem 'Toggle node definitions more'})">*definitions</walkthrough-spotlight-pointer> create a new directory called `ml_models`, `outputs`, `sources`, `staging`:

   ![](../rsc/newdirectory.png)

3. Click on `ml_models` directory and create the following file:
      ```
      logistic_regression_model.sqlx
      ```
   Copy the contents to each of those files: (**Info:** Until you have copied all contents, Dataform will display calculated compilation errors. Those will disappear, once all files are copied)

   The file contents can be found in our git repository under `ELT/definitions/`.

    <walkthrough-editor-open-file filePath="ELT/definitions/ml_models/logistic_regression_model.sqlx">`logistic_regression_model`</walkthrough-editor-open-file>
    
4. Click on `outputs` directory and create the following file:
      ```
      churn_propensity.sqlx
      ```
  Copy the contents to each of those files: 
   

  <walkthrough-editor-open-file filePath="ELT/definitions/outputs/churn_propensity.sqlx">`churn_propensity`</walkthrough-editor-open-file>
    
5. Click on `sources` directory and create the following file:
      ```
      analytics_events.sqlx
      ```
    Copy the contents to each of those files:

    <walkthrough-editor-open-file filePath="ELT/definitions/sources/analytics_events.sqlx">`analytics_events`</walkthrough-editor-open-file>
    
6. Click on `staging` directory and create the following files:
      ```
      user_aggregate_behaviour.sqlx
      ```
      ```
      user_demographics.sqlx
      ```
      ```
      user_returninginfo.sqlx
      ```
      Copy the contents to each of those files:

    <walkthrough-editor-open-file filePath="ELT/definitions/staging/user_aggregate_behaviour.sqlx">`user_aggregate_behaviour`</walkthrough-editor-open-file>
    <walkthrough-editor-open-file filePath="ELT/definitions/staging/user_demographics.sqlx">`user_demographics`</walkthrough-editor-open-file>
    <walkthrough-editor-open-file filePath="ELT/definitions/staging/user_returninginfo.sqlx">`user_returninginfo`</walkthrough-editor-open-file>


Note: Analyze the content of the sqlx file, we could use Gemini Code assist to get explanations.

Let's ask Gemini:

1. Open Gemini Code Assist <img style="vertical-align:middle" src="https://www.gstatic.com/images/branding/productlogos/gemini/v4/web-24dp/logo_gemini_color_1x_web_24dp.png" width="8px" height="8px"> on the left hand side.
2. Insert ``Please explain how the user_aggregate_behavior.sqlx file works`` into the Gemini prompt.

We still have 3 files to configure before we execute the workflow:

Create and Copy the contents to each of those `.json` files. The files should be copied under the *definitions directory within Dataform:
```
dataform.json
```
```
package-lock.json
```
```
package.json
```

<walkthrough-editor-open-file filePath="ELT/dataform.json">`dataform.json`</walkthrough-editor-open-file>
<walkthrough-editor-open-file filePath="ELT/package-lock.json">`package-lock.json`</walkthrough-editor-open-file>
<walkthrough-editor-open-file filePath="ELT/package.json">`package.json`</walkthrough-editor-open-file>

Notice the usage of `$ref` in line 12, of `ELT/definitions/ml_models/logistic_regression_model.sqlx`. The advantages of using `$ref` in Dataform are

* Automatic Reference Management: Ensures correct fully-qualified names for tables and views, avoiding hardcoding and simplifying environment configuration.  
* Dependency Tracking: Builds a dependency graph, ensuring correct creation order and automatic updates when referenced tables change.  
* Enhanced Maintainability: Supports modular and reusable SQL scripts, making the codebase easier to maintain and less error-prone.

***

### **Execute Dataform workflows**

Run the dataset creation by **Tag**. Tag allows you to just execute parts of the workflow and not the entire workflow. 

1. Click on <walkthrough-spotlight-pointer locator="semantic({button 'Start execution'})">Start execution</walkthrough-spotlight-pointer> > <walkthrough-spotlight-pointer locator="text('Tags')">Tags</walkthrough-spotlight-pointer> \> <walkthrough-spotlight-pointer locator="text('Multiple Tags')"> Multiple Tags </walkthrough-spotlight-pointer>

2. After selecting the default srvice account and the necessary Tags, click `Start execution`

3. Click on <walkthrough-spotlight-pointer locator="semantic({link 'Details'})">DETAILS</walkthrough-spotlight-pointer>

    Notice the Access Denied error on BigQuery for the dataform service account `{{ DATAFORM_SA }}`

4. Go to [IAM & Admin](https://console.cloud.google.com/iam-admin)

5. Click on <walkthrough-spotlight-pointer locator="semantic({button 'Grant access'})">GRANT ACCESS</walkthrough-spotlight-pointer> and grant `BigQuery Data Editor , BigQuery Job User and BigQuery Connection User` to the principal (service account) `{{ DATAFORM_SA }}`.

6. Click on <walkthrough-spotlight-pointer locator="semantic({button 'Save'})">SAVE</walkthrough-spotlight-pointer>

  Note: If you encounter a policy update screen, just click on update.

7. Go back to [Dataform](https://console.cloud.google.com/bigquery/dataform) within in BigQuery, and retry <walkthrough-spotlight-pointer locator="semantic({button 'Start execution'})">Start execution</walkthrough-spotlight-pointer> > <walkthrough-spotlight-pointer locator="text('tags')">Tags</walkthrough-spotlight-pointer> \> <walkthrough-spotlight-pointer locator="semantic({button 'Start execution'})"> Start execution</walkthrough-spotlight-pointer>. \
Notice the execution status. It should be a success.  
 
8. Lastly, go to Compiled graph and explore it.
Go to [Dataform](https://console.cloud.google.com/bigquery/dataform)\> <walkthrough-spotlight-pointer locator="text('datajourney-repository')">datajourney-repository</walkthrough-spotlight-pointer>>`datajourney-workspace` \> <walkthrough-spotlight-pointer locator="semantic({tab 'Compiled graph tab'})">COMPILED GRAPH</walkthrough-spotlight-pointer>

***


## Lab 5. Machine Learning Datathon

<walkthrough-tutorial-duration duration="70"></walkthrough-tutorial-duration>
<walkthrough-tutorial-difficulty difficulty="2"></walkthrough-tutorial-difficulty>

Now that we learned how to ingest data into BigQuery from PubSub Messages and transform them via ETL or ELT, let's continue with the [next step in the end-to-end data journey](https://github.com/NucleusEngineering/data-journey/blob/main/rsc/architecture.png): Getting insights from data via Machine Learning.

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

### *NEW* Lab 6. Veo - Media generation lab [Optional]

### *NEW* Lab 7. Data Science Agent with ADK [Optional]

You can access all of our labs on our [Github](https://github.com/NucleusEngineering/data-journey/tree/main/ML). After downloading the different lab files you can upload and run them in for example our **VertexAI Colab Enterprise** Notebook environment.

**Have fun!**


