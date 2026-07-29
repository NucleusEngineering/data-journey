# Copyright 2023 Google

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json
import time

import config

import apache_beam as beam
from apache_beam import combiners
from apache_beam.transforms import trigger
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.io.gcp.pubsub import ReadFromPubSub
from apache_beam.io.gcp.bigquery import BigQueryDisposition, WriteToBigQuery
from apache_beam.runners import DataflowRunner


def streaming_pipeline(project, region):

    subscription = "projects/{}/subscriptions/dj_subscription_dataflow".format(project)

    bucket = "gs://{}-gaming-events/df_templates".format(project)

    # Defining pipeline options.
    options = PipelineOptions(
        streaming=True,
        project=project,
        region=region,
        staging_location="%s/staging" % bucket,
        temp_location="%s/temp" % bucket,
        subnetwork='regions/europe-west1/subnetworks/terraform-network',
        service_account_email='data-journey-pipeline@{}.iam.gserviceaccount.com'.format(
            project),
        max_num_workers=1
    )

    # Defining pipeline.
    p = beam.Pipeline(DataflowRunner(), options=options)

    # Receiving message from Pub/Sub & parsing json from string.
    json_message = (p
                    # Listining to Pub/Sub.
                    | "Read Topic" >> ReadFromPubSub(subscription=subscription)
                    # Parsing json from message string.
                    | "Parse json" >> beam.Map(json.loads))

    # Extracting user pseudo ids and event names.
    extract = (json_message | "Map" >> beam.Map(lambda x: { "user_pseudo_id": x["user_pseudo_id"], "event_name": x["event_name"]}))

    # Appying windowing funtion
    fixed_windowed_items = (extract
                          | "CountEventsPerMinute" >> beam.WindowInto(beam.window.FixedWindows(60),
                                                                trigger=trigger.AfterWatermark(early=trigger.AfterProcessingTime(60), late=trigger.AfterCount(1)),
                                                                accumulation_mode=trigger.AccumulationMode.DISCARDING)
                       )

    # Calculating numbers of events per user in a minute
    number_events =  (fixed_windowed_items | "Read" >> beam.Map(lambda x: (x["user_pseudo_id"], 1))
                                        | "Grouping users" >> beam.GroupByKey()
                                        | "Count" >> beam.CombineValues(sum)
                                        | "Map to dictionaries" >> beam.Map(lambda x: {"user_pseudo_id": x[0], "event_count": int(x[1])}))
    
    # Writing summed values to BigQuery
    dataflow_schema = "user_pseudo_id:STRING, event_count:INTEGER"
    dataflow_table = "{}:data_journey.dataflow".format(project)

    number_events| "Write Summed Values To BigQuery" >> WriteToBigQuery(table=dataflow_table, schema=dataflow_schema,
                                                                        create_disposition=BigQueryDisposition.CREATE_IF_NEEDED,
                                                                        write_disposition=BigQueryDisposition.WRITE_APPEND)
                                                                              
    return p.run()

if __name__ == '__main__':
    GCP_PROJECT = config.project_id
    GCP_REGION = config.location

    streaming_pipeline(project=GCP_PROJECT, region=GCP_REGION)
