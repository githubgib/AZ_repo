pipeline {
    agent {label 'linux'}

    environment {
        CONDA_ENV_NAME = "aida-transcriber"
        AIDA_CONTAINER_NAME = "aida-lambda-container"
        WORKSPACE="gibworkspace"
    }

    stages {
        stage('Install') {
            steps {
                script {
                    try {
                        echo "Installing Miniforge..."
                        sh 'wget https://github.com/conda-forge/miniforge/releases/download/4.11.0-0/Miniforge3-4.11.0-0-Linux-x86_64.sh -nv -O miniforge.sh'
                        sh 'bash miniforge.sh -b -p $WORKSPACE/miniforge'
                        echo "Miniforge installed successfully"

                        echo "Creating Conda environment..."
                        sh "conda env create -p $WORKSPACE/env/aida-transcriber -f $WORKSPACE/jenkins_env.yml --force"
                        echo "Conda environment created successfully"

                        echo "Activating Conda environment..."
                        sh "source $WORKSPACE/miniforge/etc/profile.d/conda.sh && conda activate $WORKSPACE/env/${CONDA_ENV_NAME}"
                        echo "Conda environment activated successfully"

                        echo "Checking 'transcriber' installation..."
                        sh "which transcriber"
                    } catch (Exception e) {
                        echo "Failed to install Conda environment: ${e}"
                        error "Failed to install Conda environment"
                    }
                }
            }
        }

        stage('Running flake8') {
            steps {
                script {
                    try {
                        echo "Reactivating Conda environment..."
                        sh "source $WORKSPACE/miniforge/etc/profile.d/conda.sh && conda activate $WORKSPACE/env/${CONDA_ENV_NAME}"
                        echo "Conda environment reactivated successfully"

                        echo "Running Flake8..."
                        sh "flake8 --exclude=.venv --format pylint --ignore=E722 deployment-packages/edc-fetcher deployment-packages/edc-pdf-jsons-combiner"
                    } catch (Exception e) {
                        echo "Failed to run Flake8: ${e}"
                        error "Failed to run Flake8"
                    }
                }
            }
        }
        
    }

    post { 
        always {
            script {
                echo "Stopping and removing Docker container..."
                sh "docker stop ${AIDA_CONTAINER_NAME}-${BUILD_NUMBER} || true && sleep 5 && docker rm --force ${AIDA_CONTAINER_NAME}-${BUILD_NUMBER} || true"
                echo "Docker container stopped and removed"
            }
        }
    }
}
