# Apply transformation, aggregation & bring data to BigQuery using Dataflow
Cloud Run works smooth to apply simple data transformations. On top of that it scales to 0. So why not stop right there?

Let's think one step further. Imagine for example you need to apply aggregations, not only transformations. 
For example, you might need to support a real time dashboard to display the most active users made every minute (aggregation over multiple datapoints). Or you might want to apply real time ML inference of a demanding ML model (distributed compute) before data is written into your Data Warehouse.

For extremely latency sensitive applications, and cases in which aggregations or distributed compute make the transformations stateful neither ELT nor Cloud Run will do the job.
This is where [Apache Beam](https://beam.apache.org/documentation/basics/) comes to shine!

Dataflow is a great tool to integrate into your pipeline for high volume data streams with complex transformations and aggregations.
It is based on the open-source data processing framework Apache Beam.

</details>

For the challenges below let's reference the working directory:

```cd ETL/Dataflow```

## Challenge 1.1 
First component of our dataflow ETL pipeline is a BigQuery Table named `dataflow`, and data_journey dataset if not previously created.

The BigQuery Table should make use of the schema file: user_pseudo_id:STRING and event_count:INTEGER.

The processing service will stream the transformed data into this table.

<details><summary>Hint</summary>

The [BigQuery documentation](https://cloud.google.com/bigquery/docs/tables) might be helpful to follow.

</details>

<details><summary>Suggested Solution</summary>

Run this command

```
bq --location=$GCP_REGION mk --dataset $GCP_PROJECT:data_journey
bq mk --location=$GCP_REGION --table $GCP_PROJECT:data_journey.dataflow user_pseudo_id:STRING,event_count:INTEGER
```

OR follow the documentation on how to [create a BigQuery table with schema through the console](https://cloud.google.com/bigquery/docs/tables#console).

</details>


Second component is the connection between Pub/Sub topic and Dataflow job.

Define a Pub/Sub subscription named `dj_subscription_dataflow` that can serve this purpose.
You will define the actual dataflow job in the next step.

<details><summary>Hint</summary>

Read about [types of subscriptions](https://cloud.google.com/pubsub/docs/subscriber) and [how to create them](https://cloud.google.com/pubsub/docs/create-subscription#create_subscriptions).

</details>

<details><summary>Suggested Solution</summary>

You will need to create a Pull Subscription to the Pub/Sub topic we already defined.
This is a fundamental difference to the Push subscriptions we encountered in the previous two examples.
Dataflow will pull the data points from the queue independently, depending on worker capacity.

Use this command: 

```
gcloud pubsub subscriptions create dj_subscription_dataflow \
    --topic=dj-pubsub-topic
```

OR 

read how it can be [defined via the console](https://cloud.google.com/pubsub/docs/create-subscription#pull_subscription).

</details>



## Challenge 1.2
Finally, all we are missing is your Dataflow job to apply transformations, aggregations and connect Pub/Sub queue with BigQuery Sink.

[Templates](https://cloud.google.com/dataflow/docs/concepts/dataflow-templates) let you create Dataflow jobs based on pre-existing code. That makes it quick to set up and reusable.

You need to apply custom aggregations on the incoming data.
That means you need to create a dataflow job based on a [flex-template](https://cloud.google.com/dataflow/docs/guides/templates/using-flex-templates).

Find & examine the pipeline code in `.ETL/Dataflow/dataflow_processing.py`.

The pipeline is missing some code snippets. You will have to add three code snippets in `streaming_pipeline()`.

You need to design a pipeline that calculates number of events per user per 1 minute (they don't have to be unique).
Ideally, we would like to see per one 1 hour, but for demonstration purposese we will shorten to 1 minute.

The aggregated values should be written into your BigQuery table.

Before you start coding replace the required variables in `config.py` so you can access them safely in `dataflow_processing.py`.

<details><summary>Hint: Read from PubSub Transform</summary>

The [Python Documentation](https://beam.apache.org/releases/pydoc/current/apache_beam.io.gcp.pubsub.html) should help.

</details>

<details><summary>Hint: Data Windowing</summary>

This is a challenging one. There are multiple ways of solving this.

Easiest is a [FixedWindows](https://beam.apache.org/documentation/programming-guide/#using-single-global-window) with [AfterProcessingTime trigger](https://beam.apache.org/documentation/programming-guide/#event-time-triggers).

</details>

<details><summary>Hint: Counting the events per user</summary>

Check out some core beam transforms: (https://beam.apache.org/documentation/programming-guide/#core-beam-transforms).

</details>

<details><summary>Suggested Solution: Read from PubSub Transform</summary>

The code should look something like this:
```
    json_message = (p
                    # Listining to Pub/Sub.
                    | "Read Topic" >> ReadFromPubSub(subscription=subscription)
                    # Parsing json from message string.
                    | "Parse json" >> beam.Map(json.loads))
```

</details>

<details><summary>Suggested Solution: Data Windowing</summary>

The code should look something like this:    
```
    fixed_windowed_items = (extract
                          | "CountEventsPerMinute" >> beam.WindowInto(beam.window.FixedWindows(60),
                                                                trigger=trigger.AfterWatermark(early=trigger.AfterProcessingTime(60), late=trigger.AfterCount(1)),
                                                                accumulation_mode=trigger.AccumulationMode.DISCARDING)
                       )
```

</details>

<details><summary>Suggested Solution: Counting the events per user</summary>
    
The code should look something like this:    
```
    number_events =  (fixed_windowed_items | "Read" >> beam.Map(lambda x: (x["user_pseudo_id"], 1))
                                        | "Grouping users" >> beam.GroupByKey()
                                        | "Count" >> beam.CombineValues(sum)
                                        | "Map to dictionaries" >> beam.Map(lambda x: {"user_pseudo_id": x[0], "event_count": int(x[1])})) 
```
    
</details>

Before finishing this section make sure to update the project_id and region in `.ETL/Dataflow/config.py`.

## Challenge 1.3

To create a flex-template we first need to build the pipeline code as container in the Container Registry.

Note: Add data-journey-pipeline@datajourney[..]serviceaccount.com for artifact reader to avoid following error: "denied: Permission "artifactregistry.repositories.downloadArtifacts" denied on resource"

Build the Dataflow folder content as container named `beam-processing-flex-template` to your Container Registry.

<details><summary>Suggested Solution</summary>
    
```    
gcloud builds submit --tag gcr.io/$GCP_PROJECT/beam-processing-flex-template
```
</details>

Create a Cloud Storage Bucket named `gs://<project-id>-gaming-events`. Create a Dataflow flex-template based on the built container and place it in your new GCS bucket.

<details><summary>Hint</summary>

Checkour the [docs](https://cloud.google.com/sdk/gcloud/reference/dataflow/flex-template/build) on how to build a dataflow flex-template.

</details>

<details><summary>Suggested Solution</summary>

Create a new bucket by running 
```
gsutil mb -c standard -l europe-west1 gs://$GCP_PROJECT-gaming-events
```

Build the flex-template into your bucket using:
```
gcloud dataflow flex-template build gs://$GCP_PROJECT-gaming-events/df_templates/dataflow_template.json --image=gcr.io/$GCP_PROJECT/beam-processing-flex-template --sdk-language=PYTHON
```
</details>

## Challenge 1.4

Run a Dataflow job based on the flex-template you just created.

The job creation will take 5-10 minutes.

<details><summary>Hint</summary>

The [documentation on the flex-template run command](https://cloud.google.com/sdk/gcloud/reference/dataflow/flex-template/run) should help.

</details>


<details><summary>Suggested Solution</summary>

```
gcloud dataflow flex-template run dataflow-job --template-file-gcs-location=gs://$GCP_PROJECT-gaming-events/df_templates/dataflow_template.json --region=europe-west1 --service-account-email="data-journey-pipeline@$GCP_PROJECT.iam.gserviceaccount.com" --max-workers=1 --network=terraform-network
```

</details>

## Validate Dataflow ETL pipeline implementation

You can now stream website interaction data points through your Cloud Run Proxy Service, Pub/Sub Topic & Subscription, Dataflow job and all the way up to your BigQuery destination table.

Run 

```
python3 synth_json_stream.py --endpoint=$ENDPOINT_URL --bucket=$BUCKET --file=$FILE
```

to direct an artificial click stream at your pipeline. No need to reinitialize if you still have the clickstream running from earlier.

After a minute or two you should find your BigQuery destination table populated with data points. 
The metrics of Pub/Sub topic and Subscription should also show the throughput.
Take a specific look at the un-acknowledged message metrics in Pub/Sub.
If everything works as expected it should be 0.
