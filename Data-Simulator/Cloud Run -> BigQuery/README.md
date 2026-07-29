# Part 2: Bring raw data to BigQuery as efficient as possible

Now that your data ingestion is working correctly we move on to set up your processing infrastructure.
Data processing infrastructures often have vastly diverse technical and business requirements. 
We will find the right setup for three completely different settings.


[ELT is in!](https://cloud.google.com/bigquery/docs/migration/pipelines#elt)  Imagine you don't actually want to set up processing.
Instead, you would like to build a [modern Lakehouse structure](https://cloud.google.com/blog/products/data-analytics/open-data-lakehouse-on-google-cloud) with ELT processing.
Therefore, your  main concern at this point is to bring the incoming raw data into your Data Warehouse as cost-efficient as possible.
Data users will worry about the processing.

To start out we aim for rapid iteration. We plan using BigQuery as Data Lakehouse - Combining Data Warehouse and Data Lake.

To implement our lean ELT pipeline we need:
- BigQuery Dataset
- BigQuery Table
- Pub/Sub BigQuery Subscription

Start with creating a BigQuery Dataset named `data_journey`. The Dataset should contain a table named `pubsub_direct`.

Continue by setting up a Pub/Sub Subscription named `dj_subscription_bq_direct` that directly streams incoming messages in the BigQuery Table you created. 

To create the BigQuery Dataset run:

```
bq --location=$GCP_REGION mk --dataset $GCP_PROJECT:data_journey
```

To create the BigQuery destination table run:
```
bq mk --location=$GCP_REGION --table $GCP_PROJECT:data_journey.pubsub_direct data:STRING
```

Alternatively create the [Dataset](https://cloud.google.com/bigquery/docs/datasets#create-dataset) and [Table](https://cloud.google.com/bigquery/docs/tables#create_an_empty_table_with_a_schema_definition) via Cloud Console as indicated in the documentation.


To create the Pub/Sub subscription in the console run:

```

gcloud pubsub subscriptions create dj_subscription_bq_direct --topic=dj-pubsub-topic --bigquery-table=$GCP_PROJECT:data_journey.pubsub_direct

```

Alternatively, the [documentation](https://cloud.google.com/pubsub/docs/create-subscription#pubsub_create_bigquery_subscription-console) walks step-by-step through the creation of a BigQuery subscription in the console.

</details>

## Validate ELT Pipeline implementation

You can now stream website interaction data points through your Cloud Run Proxy Service, Pub/Sub Topic & Subscription all the way up to your BigQuery destination table.

Run 

```
python3 synth_json_stream.py --endpoint=$ENDPOINT_URL --bucket=$BUCKET --file=$FILE
```

to direct an artificial click stream at your pipeline. If your datastream is still running from earlier you don't need to initiate it again.

After a minute or two you should find your BigQuery destination table populated with data points. 
The metrics of Pub/Sub topic and Subscription should also show the throughput.
Take a specific look at the un-acknowledged message metrics in Pub/Sub.
If everything works as expected it should be 0.
