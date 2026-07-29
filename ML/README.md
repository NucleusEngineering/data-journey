# Datathon-customer-churn

User retention can be a major challenge across industries. To retain a larger percentage of users after their first use of an app, developers can take steps to motivate and incentivize certain users to return. But to do so, developers need to identify the propensity of any specific user returning after the first 24 hours. 
In this hackathon, we will discuss how you can use BigQuery ML to run propensity models on Google Analytics 4 data from an example gaming app data to determine the likelihood of specific users returning to your app.

![architecture](assets/overview.png)

## Lab 1
*  Pre-process the raw event data in views 
*  Identify users & the label feature
*  Process demographic features
*  Process behavioral features
*  Create the training and evaluation sets 

## Lab 2 
*  Data exploration on the training set
*  Train your classification models using BQML
*  Perform feature engineering using ```TRANSFORM``` in BQML
*  Evaluate the model using BQML
*  Make predictions using BQML

## Lab 3
*  Export and register our trained BQML model to Vertex AI Model Registry (e.g tensorflow format)
*  Deploy our registered model to a new endpoint
*  Deploy another updated model to the same endpoint (traffic split 50%)
*  Enable Prediction data drift in our endpoint for submitting a skewed payload 

## Lab 4
*  Orchestrate Lab 2 and Lab 3 using Vertex Pipelines
