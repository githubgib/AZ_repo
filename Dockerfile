ARG BASE_IMG=public.ecr.aws/lambda/python:3.8
FROM ${BASE_IMG}

ARG LAMBDA_TASK_ROOT='root'

# Please note this is used by both the Jenkins build
# and the codebuild used by application, be careful
# with changes.

ARG RESOURCES_PATH="deployment-packages/extracting/resources"

# Install GCC for python-Levenshtein 
RUN yum -y install gcc && yum -y clean all && rm -fr /var/cache

# Copy the packages we need to the task
COPY deployment-packages/document-transcriber/ ${LAMBDA_TASK_ROOT}/document-transcriber

# Install python requirements
RUN pip install ${LAMBDA_TASK_ROOT}/document-transcriber && rm -rf /root/.cache

# TODO: Determine why we do this and whether we need to here
ENV PYTHONHASHSEED=123

# Install lambda-specific python packages
RUN pip install jsonschema~=4.5.1 && rm -rf /root/.cache

# Copy over the Lambda wrapper data and scripts we need
COPY lambda/app.py ${LAMBDA_TASK_ROOT}
COPY lambda/schemas ${LAMBDA_TASK_ROOT}/schemas
COPY lambda/data ${LAMBDA_TASK_ROOT}/data

# This is a potential fix for the issue of e.g.
# https://jenkins.astrazeneca.net/job/R_and_D_IT/job/AIDA/job/Harmonization%20CI/view/change-requests/job/PR-132/3/
# Using fix from
# https://stackoverflow.com/questions/51115856/docker-failed-to-export-image-failed-to-create-image-failed-to-get-layer
RUN true

COPY ${RESOURCES_PATH} ${LAMBDA_TASK_ROOT}/${RESOURCES_PATH}
