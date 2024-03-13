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
        
    }

    post { 
        always {
            sh '''# Stop and remove the container process if its running
                  docker stop ${AIDA_CONTAINER_NAME}-${BUILD_NUMBER} || true && sleep 5 && docker rm --force ${AIDA_CONTAINER_NAME}-${BUILD_NUMBER} || true'''
            }
    }
}
