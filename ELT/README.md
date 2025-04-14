## Lab 4: Dataform (ELT)


<walkthrough-tutorial-duration duration="30"></walkthrough-tutorial-duration>
<!--{{ author('Cosmin Pintoiu', 'https://www.linkedin.com/in/cosmin-pintoiu/') }} -->
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
```bash
gcloud auth activate-service-account [Provided_USEr]
gcloud auth login
export PROJECT_NUMBER=$(gcloud projects describe "$GCP_PROJECT" --format="value(projectNumber)")
```
Now, let's follow the steps:

1. Click on <walkthrough-spotlight-pointer locator="css(a[id$=create-repository])">CREATE REPOSITORY</walkthrough-spotlight-pointer>

2. Use the following values when creating the repository:

    Repository ID: `datajourney-repository` \
    Region: `europe-west1` \
    Service Account: `Default Dataform service account`

3. And click on <walkthrough-spotlight-pointer locator="text('create')">CREATE</walkthrough-spotlight-pointer>
```bash
export DATAFORM_SA="service-${PROJECT_NUMBER}@gcp-sa-dataform.iam.gserviceaccount.com"
```
The dataform service account you see on your screen should be `{{ DATAFORM_SA }}`. We will need it later.


Next, click <walkthrough-spotlight-pointer locator="text('go to repositories')">GO TO REPOSITORIES</walkthrough-spotlight-pointer>, and then choose the <walkthrough-spotlight-pointer locator="text('hackathon-repository')">hackathon-repository</walkthrough-spotlight-pointer> you just created.



### Create a Dataform Workspace

You should now be in the <walkthrough-spotlight-pointer locator="text('development workspaces')">Development workspaces</walkthrough-spotlight-pointer> tab of the hackathon-repository page.

First, click <walkthrough-spotlight-pointer locator="text('create development workspace')">Create development workspace</walkthrough-spotlight-pointer> to create a copy of your own repository.  You can create, edit, or delete content in your repository without affecting others.


In the **Create development workspace** window, do the following:  
   1. In the <walkthrough-spotlight-pointer locator="semantic({textbox 'Workspace ID'})">Workspace ID</walkthrough-spotlight-pointer> field, enter `datajourney-workspace` or any other name you like.

   2. Click <walkthrough-spotlight-pointer locator="text('create')">CREATE</walkthrough-spotlight-pointer>
   3. The development workspace page appears.  
   4. Click on the newly created `datajourney-workspace` 
   5. Click <walkthrough-spotlight-pointer locator="css(button[id$=initialize-workspace-button])">Initialize workspace</walkthrough-spotlight-pointer>

### Adjust workflow settings

We will now set up our custom workflow.

1. Edit the `workflow_settings.yaml`file :

2. Replace `defaultDataset` value with ``{{ PROJECT_ID }}``

3. Make sure `defaultProject` value is ``{{ PROJECT_ID }}``

4. Click on <walkthrough-spotlight-pointer locator="text('install packages')">INSTALL PACKAGES</walkthrough-spotlight-pointer> ***only once***. You should see a message at the bottom of the page:

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
   Copy the contents to each of those files:

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
2. Insert ``Please explain how the user_aggregate_behavior works`` into the Gemini prompt.

We still have 3 files to configure before we execute the workflow:

Create and Copy the contents to each of those files:
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


First, let's bring the events data we will use in BQ:

```bash
cd /home/admin_/data-journey/ELT \
gcloud storage cp /home/admin_/data-journey/ELT/events gs://example-bucket-name-${GCP_PROJECT} \
bq mk --location=europe-west1 --table $GCP_PROJECT:data_journey.events \
bq load --source_format=PARQUET $GCP_PROJECT:data_journey.events
```

Run the dataset creation by **Tag**. Tag allow you to just execute parts of the workflows and not the entire workflow. 

1. Click on <walkthrough-spotlight-pointer locator="semantic({button 'Start execution'})">Start execution</walkthrough-spotlight-pointer> > <walkthrough-spotlight-pointer locator="text('tags')">Tags</walkthrough-spotlight-pointer> \> <walkthrough-spotlight-pointer locator="semantic({button 'Start execution'})"> Start execution</walkthrough-spotlight-pointer>

2. Click on <walkthrough-spotlight-pointer locator="semantic({link 'Details'})">DETAILS</walkthrough-spotlight-pointer>

    Notice the Access Denied error on BigQuery for the dataform service account `{{ DATAFORM_SA }}`

3. Go to [IAM & Admin](https://console.cloud.google.com/iam-admin)

4. Click on <walkthrough-spotlight-pointer locator="semantic({button 'Grant access'})">GRANT ACCESS</walkthrough-spotlight-pointer> and grant `BigQuery Data Editor , BigQuery Job User and BigQuery Connection User` to the principal `{{ DATAFORM_SA }}`.

5. Click on <walkthrough-spotlight-pointer locator="semantic({button 'Save'})">SAVE</walkthrough-spotlight-pointer>

  Note: If you encounter a policy update screen, just click on update.

6. Go back to [Dataform](https://console.cloud.google.com/bigquery/dataform) within in BigQuery, and retry <walkthrough-spotlight-pointer locator="semantic({button 'Start execution'})">Start execution</walkthrough-spotlight-pointer> > <walkthrough-spotlight-pointer locator="text('tags')">Tags</walkthrough-spotlight-pointer> \> <walkthrough-spotlight-pointer locator="semantic({button 'Start execution'})"> Start execution</walkthrough-spotlight-pointer>. \
Notice the execution status. It should be a success.  
 
7. Lastly, go to Compiled graph and explore it.
Go to [Dataform](https://console.cloud.google.com/bigquery/dataform)\> <walkthrough-spotlight-pointer locator="text('datajourney-repository')">datajourney-repository</walkthrough-spotlight-pointer>>`datajourney-workspace` \> <walkthrough-spotlight-pointer locator="semantic({tab 'Compiled graph tab'})">COMPILED GRAPH</walkthrough-spotlight-pointer>

***

