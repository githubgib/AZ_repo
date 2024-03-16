FROM public.ecr.aws/lambda/python:3.9

# We don't want to install libgomp on sagemaker as it doesn't work
ARG is_sagemaker="1"

# Copy the packages we need to the task
COPY deployment-packages-sida/automatic-event-adjudication ${LAMBDA_TASK_ROOT}/automatic-event-adjudication
COPY deployment-packages-sida/flattener ${LAMBDA_TASK_ROOT}/flattener

# Copy over requirements we will need
COPY deployment-packages-sida/training/requirements.txt ${LAMBDA_TASK_ROOT}/training/requirements.txt

# Copy over script we want
COPY lambda/install_dependencies.sh ${LAMBDA_TASK_ROOT}/install_dependencies.sh 

# Install python requirements 
# TODO: Document why we're using in-tree-build --use-feature=in-tree-build (deprecated pip option)
RUN pip install jmespath==1.0.1 jsonschema==4.19.1 loguru==0.7.2 pandas==2.1.1
#RUN cd training/ && pip install -r requirements.txt && cd ..
RUN cd training/ && pip install -r requirements.txt && cd .. && rm -rf /root/.cache


# Install libgomp for shared memory usage. It is not installed by default.
# Note: This does not currently work in SageMaker as it cannot access a mirror list
RUN if [[ ${is_sagemaker} == "0" ]]; then yum -y install libgomp && yum clean all && rm -rf /var/cache/yum; fi

# Install some dependencies like NLTK
# Note: We set the NLTK_DATA env variable as it is a non-standard location
ENV NLTK_DATA=${LAMBDA_TASK_ROOT}/nltk_data
RUN sh install_dependencies.sh

# Add linting tools (example: flake8 for Python linting)
RUN pip install flake8

# Set PYTHONHASHSEED
ENV PYTHONHASHSEED=123
