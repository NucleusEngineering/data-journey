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
import requests
import time
import argparse
import random
# Import the Google Cloud client library
from google.cloud import storage

def main(endpoint, bucket, file):
    # Instantiate a Google Cloud Storage client
    storage_client = storage.Client()

    # Get the bucket and blob
    bucket = storage_client.bucket(bucket)
    blob = bucket.blob(file)

    # Read the JSON file
    all_data = blob.download_as_string().splitlines()

    # Get a random line of data
    random_line = json.loads(all_data[random.randint(0, len(all_data) - 1)])

    # send request
    r = requests.post(endpoint, json=random_line)

    # print(r.text)
    print(f'{time.time()} -- {r.status_code}')


if __name__ == "__main__":
    # Parse Arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--endpoint", help="Target Endpoint")
    parser.add_argument("--bucket", help="Bucket Name")
    parser.add_argument("--file", help="JSON File to Sample From")

    args = parser.parse_args()

    endpoint = args.endpoint + '/json'
    bucket = args.bucket
    file = args.file

    while True:
        main(endpoint, bucket, file)
        time.sleep(2)
