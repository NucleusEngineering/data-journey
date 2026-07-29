#FROM gcr.io/dataflow-templates-base/python39-template-launcher-base:latest as template_launcher
FROM gcr.io/dataflow-templates-base/python3-template-launcher-base:latest as template_launcher

ARG WORKDIR=/dataflow/template
RUN mkdir -p ${WORKDIR}
WORKDIR ${WORKDIR}

# Copy local code to the container image.
COPY . ./
COPY ./requirements.txt ./
COPY ./dataflow_processing.py ./

# Flex Template ENV Vars
ENV FLEX_TEMPLATE_PYTHON_PY_FILE="${WORKDIR}/dataflow_processing.py"
ENV FLEX_TEMPLATE_PYTHON_REQUIREMENTS_FILE="${WORKDIR}/requirements.txt"

# Install requirements
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

ENTRYPOINT ["/opt/google/dataflow/python_template_launcher"]
