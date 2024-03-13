pipeline {
    agent {label 'linux_2_3'}

    environment {
        http_proxy = "http://azpzen.astrazeneca.net:9480"
        https_proxy = "http://azpzen.astrazeneca.net:9480"
        CONDA_ENV_NAME = "aida-transcriber"
        AIDA_CONTAINER_NAME = "aida-lambda-container"
    }

    stages {
        stage('Install') {
            steps {

                sh '''export http_proxy="http://seprivatezen.astrazeneca.net:9480"
                      export https_proxy="http://seprivatezen.astrazeneca.net:9480"

                      # Remove untracked files and folders from workspace
                      git clean -fdx

                      # Download and install miniforge
                      wget https://github.com/conda-forge/miniforge/releases/download/4.11.0-0/Miniforge3-4.11.0-0-Linux-x86_64.sh -nv -O miniforge.sh
                      bash miniforge.sh -b -p $WORKSPACE/miniforgea

                      # Create environment
                      conda env create -p $WORKSPACE/env/aida-transcriber -f $WORKSPACE/jenkins_env.yml --force

                      # Make conda activate available
                      source $WORKSPACE/miniforge/etc/profile.d/conda.sh

                      # Activate the environment
                      conda activate $WORKSPACE/env/${CONDA_ENV_NAME}

                      # Check that aida was installed
                      transcriber --help'''
                
            }
        }

        stage('Running flake8') {
            steps {
                // Run Flake8 on your code
                sh '''
                # Reactivate environment
                source $WORKSPACE/miniforge/etc/profile.d/conda.sh
                conda activate $WORKSPACE/env/${CONDA_ENV_NAME}
                
                # Run flake8
                flake8 --exclude=.venv --format pylint --ignore=E722 deployment-packages/edc-fetcher deployment-packages/edc-pdf-jsons-combiner'''
            }
        }

        stage('Unit tests') {
            steps {
                sh '''# Reactivate environment
                      source $WORKSPACE/miniforge/etc/profile.d/conda.sh
                      conda activate $WORKSPACE/env/${CONDA_ENV_NAME}

                      # Navigate to training directory
                      cd deployment-packages/document-transcriber/
                      
                      # Run tests
                      # Note: For some reason pytest looks in a location outside of our 
                      # CI environment for coverage, so let's disable it.
                      pytest -p no:cov'''
            }
        }

        stage('Transcriber Run') {
            steps {
                sh '''# Reactivate environment
                      source $WORKSPACE/miniforge/etc/profile.d/conda.sh
                      conda activate $WORKSPACE/env/${CONDA_ENV_NAME}
                      
                      # Run transcriber
                      transcriber run -c deployment-packages/extracting/config-jenkins/config.json'''
            }
        }
        
        stage('Transcriber Experiment') {
            steps {
                sh '''# Reactivate environment
                      source $WORKSPACE/miniforge/etc/profile.d/conda.sh
                      conda activate $WORKSPACE/env/${CONDA_ENV_NAME}
                      
                      # Run transcriber
                      transcriber experiment --no-checks -f deployment-packages/extracting/config-jenkins/experiment.nocmr.yml
                      '''
            }
        }

        stage('Validate Experiment Output') {
            steps {
                sh '''# Reactivate environment
                      source $WORKSPACE/miniforge/etc/profile.d/conda.sh
                      conda activate $WORKSPACE/env/${CONDA_ENV_NAME}

                      # Find the trace data we just made
                      TRACE_PATH=$(find ./mlruns/ -name "transcriber-md5-trace.json")

                      # Validate the file
                      python tools/validate-source-docs.py -f ${TRACE_PATH} -d deployment-packages/extracting/workspace/dummyendpoint/outputjsons -v
                      '''
            }
        }

        stage('Build Tesseract') {
            steps {
                sh '''docker build . -f lambda/Dockerfile.tesseract -t aida-transcriber-tesseract --build-arg http_proxy=${http_proxy} --build-arg https_proxy=${https_proxy}'''
            }
        }

        stage('Build Base Image') {
            steps {
                sh '''docker build . -f lambda/Dockerfile.base -t aida-transcriber-base --build-arg BASE_IMG=aida-transcriber-tesseract --build-arg http_proxy=${http_proxy} --build-arg https_proxy=${https_proxy}'''
            }
        }

        stage('Build Lambda Image') {
            steps {
                sh '''# Find the model we made earlier
                      MODEL_PATH=$(dirname -- "$(find ./ -name "MLmodel")")
                      echo "Using model at: ${MODEL_PATH}"

                      # Stop container if running
                      docker stop ${AIDA_CONTAINER_NAME}-${BUILD_NUMBER} || true && docker rm ${AIDA_CONTAINER_NAME}-${BUILD_NUMBER} || true
                
                      # Build the Lambda image
                      docker build . -f lambda/Dockerfile.lambda -t aida-transcriber-lambda --build-arg MODEL_PATH=${MODEL_PATH} --build-arg http_proxy=${http_proxy} --build-arg https_proxy=${https_proxy}'''
            }
        }
        
        stage('Lambda Request (Type)') {
            steps {
                
                sh '''# Set the container running
                      docker run --rm -p 9123:8080 --env AIDA_FORCE_LOCAL=1 -d --name ${AIDA_CONTAINER_NAME}-${BUILD_NUMBER} aida-transcriber-lambda
                      docker logs ${AIDA_CONTAINER_NAME}-${BUILD_NUMBER}
                      # Unset the proxy otherwise ZScalar spoils everything
                      unset http_proxy
                      unset https_proxy

                      # Wait for container to run otherwise we get "connection reset by peer" error
                      sleep 5

                      # Send the mock request to the container
                      curl -v -o curl-output.txt -X POST -H "Content-Type: application/json" -f -d @lambda/example-lambda-request.json 'http://localhost:9123/2015-03-31/functions/function/invocations'
                      cat curl-output.txt

                      # Need to check that the response is successful
                      # --exit-status exits with non-0 if result is null or false
                      # TODO: This really needs a better way
                      jq --exit-status '.studyId' curl-output.txt'''
            }
        }
        
        stage('Lambda Request (Multi)') {
            steps {
                sh '''# Unset the proxy otherwise ZScalar spoils everything
                      unset http_proxy
                      unset https_proxy
                      
                      # Wait for container to run otherwise we get "connection reset by peer" error
                      sleep 100
                      
                      # Send the mock request to the container
                      curl -v -o curl-output.txt -X POST -H "Content-Type: application/json" -f -d @lambda/example-multi-lambda-request.json 'http://localhost:9123/2015-03-31/functions/function/invocations'
                      cat curl-output.txt

                      # Need to check that the response is
                      # --exit-status exits with non-0 if result is null or false
                      # TODO: This really needs a better way
                      jq --exit-status '.studyId' curl-output.txt'''
            }
        }
        
    }

    post { 
        always {
            sh '''# Stop and remove the container process if its running
                  docker stop ${AIDA_CONTAINER_NAME}-${BUILD_NUMBER} || true && sleep 5 && docker rm --force ${AIDA_CONTAINER_NAME}-${BUILD_NUMBER} || true'''
            }
    }
}
