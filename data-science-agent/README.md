# Data Science with Multiple Agents

## Overview

This part of the repository focuses on a multi-agent system specifically designed for in-depth gaming churn analysis. It combines several specialized agents to handle various stages, from retrieving player and game interaction data via BigQuery to executing complex data manipulations. The system leverages BigQuery ML (BQML) for predictive churn modeling and generates insightful text responses and data visualizations (plots, graphs) to explore churn drivers and patterns.


### Architecture
![Data Science Architecture](data-science-architecture.png)

### Key Features

*   **Multi-Agent Architecture:** Utilizes a top-level agent that orchestrates sub-agents, each specialized in a specific task.
*   **Database Interaction (NL2SQL):** Employs a Database Agent to interact with BigQuery using natural language queries, translating them into SQL.
*   **Data Science Analysis (NL2Py):** Includes a Data Science Agent that performs data analysis and visualization using Python, based on natural language instructions.
*   **Machine Learning (BQML):** Features a BQML Agent that leverages BigQuery ML for training and evaluating machine learning models.
*   **Code Interpreter Integration:** Supports the use of a Code Interpreter extension in Vertex AI for executing Python code, enabling complex data analysis and manipulation.
*   **ADK Web GUI:** Offers a user-friendly GUI interface for interacting with the agents.
*   **Testability:** Includes a comprehensive test suite for ensuring the reliability of the agents.


## Setup and Installation

### Prerequisites

*   **Google Cloud Account:** You need a Google Cloud account with BigQuery enabled.
*   **Python 3.12+:** Ensure you have Python 3.12 or a later version installed.
*   **Poetry:** Install Poetry by following on the official Poetry website: https://python-poetry.org/docs/.


### Project Setup:

1.  **Clone the Repository:**

    ```bash
    git clone https://github.com/NucleusEngineering/data-journey.git
    cd data-journey/data-science-agent
    ```

2.  **Install Dependencies with Poetry:**

    ```bash
    poetry install
    ```

    This command reads the `pyproject.toml` file and installs all the necessary dependencies into a virtual environment managed by Poetry. If it doesn't work try pip poetry install and restart your shell session.

3.  **Activate the Poetry Shell:**

    ```bash
    poetry env activate
    ```

    This activates the virtual environment, allowing you to run commands within the project's environment. To make sure the environment is active, use for example:
    
    ```bash
    poetry env list
    ```
    
    This is the output you should get:  data-science-FAlhSuLn-py3.13 (Activated).

    If the above command did not activate the environment for you, you can also activate it through:

     ```bash
    source $(poetry env info --path)/bin/activate
    ```

5.  **Set up Environment Variables:**
    Rename the file ".env-example" to ".env" and fill the below values:

    ```bash
    GOOGLE_GENAI_USE_VERTEXAI=1
    GOOGLE_CLOUD_PROJECT='YOUR_VALUE_HERE'
    GOOGLE_CLOUD_LOCATION='YOUR_VALUE_HERE'
    ```
    Make sure to source the variables as below:
     ```bash
    source .env
    ```
7.  **BigQuery Setup:**
 
    *   First, set the BigQuery project ID (same as your project id)  and `BQ_DATASET_ID` in the `.env` file. 
    *   You will find the datasets inside 'data-science-agent/utils/data/'.
        Make sure you are still in the working directory (`data-journey/data-science-agent`). To load the test and train tables into BigQuery, run the following commands:
        ```bash
        python3 data_science/utils/create_bq_table.py
        ```
        If you get dotenv error, try pip install python-dotenv.

8.  **BQML Setup:**
    The BQML Agent uses the Vertex AI RAG Engine to query the full BigQuery ML Reference Guide.

    Before running the setup, ensure your project ID is added in .env file: `"GOOGLE_CLOUD_PROJECT"`.
    Leave the corpus name empty in the .env file: `BQML_RAG_CORPUS_NAME = ''`. The corpus name will be added automatically once it's created.

    To set up the RAG Corpus for your project, run the methods `create_RAG_corpus()` and `ingest_files()` in
    `data-science/data_science/utils/reference_guide_RAG.py` by running the below command from the working directory:

    ```bash
    python3 data_science/utils/reference_guide_RAG.py
    ```


9.  **(optional step) Other Environment Variables:**

    *   `NL2SQL_METHOD`: (Optional) Either `BASELINE` or `CHASE`. Sets the method for SQL Generation. Baseline uses Gemini off-the-shelf, whereas CHASE uses [CHASE-SQL](https://arxiv.org/abs/2410.01943)
    *   `CODE_INTERPRETER_EXTENSION_NAME`: (Optional) The full resource name of
        a pre-existing Code Interpreter extension in Vertex AI. If not provided,
        a new extension will be created. (e.g.,
        `projects/<YOUR_PROJECT_ID>/locations/<YOUR_LOCATION>/extensions/<YOUR_EXTENSION_ID>`).
        Check the logs/terminal for the ID of the newly created Code Interpreter
        Extension and provide the value in your environment variables to avoid
        creating multiple extensions.

    From the terminal:

    ```bash
    export CODE_INTERPRETER_EXTENSION_NAME='projects/<YOUR_PROJECT_ID>/locations/us-central1/extensions/<YOUR_EXTENSION_ID>'
    ```

## Running the Agent

You can run the agent using the ADK command in your terminal.
from the working directory:

1.  Run agent in CLI:

    ```bash
    poetry run adk run data_science
    ```

2.  Run agent with ADK Web UI:
    ```bash
    poetry run adk web
    ```
    Select the data-science from the dropdown
    ** If you get some errors, try installing poetry again.

### Example Agent Interaction

Here's a quick example of how a user might interact with the Data Science Multi-Agent System:

> ´**User:** Hi, What data do you have access to?

> **Agent:**  I have access to two tables: `train` and `test`. These tables contain user engagement data, including country, operating system, language, and various engagement metrics, as well as a churned label.

> **User:** Please generate a plot of user distribution per country.

> **Agent:**  Result: The bar plot displays the user distribution per country, with the United States having the highest number of users.

> Explanation:
  I queried the database to retrieve the number of users per country from the train table.  
  I used the data science agent to generate a bar plot visualizing this distribution.
  The x-axis of the plot represents the countries, and the y-axis represents the number of users.
  The plot clearly shows that the United States has a significantly higher number of users compared to other countries.

> **User:** What kinds of forecasting models can I train in BQML?

> **Agent:** You can train several types of forecasting models in BQML, including ARIMA, Exponential Smoothing, and Temporal Fusion Transformer (TFT) models. Would you like to proceed with training a forecasting model?

> **User:** Yes

> **Agent:** Okay, before proceeding, let's confirm the project and dataset ID for BQML. We'll be using the `PROJECT_ID` project and the `BQ_DATASET_ID` dataset. Does that sound right?

> **User:** Yes

> **Agent:** The BQML supports `ARIMA_PLUS`, `ARIMA_PLUS_XREG`.

>To proceed, I need to know which model you'd like to use. I also need to know the following:

>*   The name of the column that provides the time points (e.g., 'date').
>*   The name of the column that contains the data to forecast (e.g., 'num_sold').
>*   Do you want to fit and forecast multiple time series using a single query? If so, what are the ID columns?
