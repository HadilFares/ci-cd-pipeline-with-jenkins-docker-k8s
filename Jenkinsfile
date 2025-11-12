pipeline {
    agent {
        kubernetes {
            label 'ci-agent'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ['\$(JENKINS_SECRET)', '\$(JENKINS_NAME)']
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
  
  - name: docker
    image: docker:latest
    command: ['cat']
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"

  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }
    
    environment {
        DOCKER_IMAGE = 'hadilfares/nodeapp'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        K8S_NAMESPACE = 'jenkins'  
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                container('jnlp') {
                    git branch: 'master', url: 'https://github.com/HadilFares/ci-cd-pipeline-with-jenkins-docker-k8s.git'
                }
            }
        }
        
        stage('Install kubectl in jnlp') {
            steps {
                container('jnlp') {
                    script {
                        sh """
                            # Install kubectl in the jnlp container
                            curl -LO "https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                            chmod +x kubectl
                            mv kubectl /usr/local/bin/
                            
                            # Verify installation
                            kubectl version --client
                        """
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    script {
                        echo "Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        sh """
                            docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                            docker images | grep ${DOCKER_IMAGE}
                        """
                    }
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                container('docker') {
                    script {
                        withCredentials([usernamePassword(
                            credentialsId: 'dockerhublogin',  
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )]) {
                            sh """
                                echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                                docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            """
                        }
                    }
                }
            }
        }
        
        stage('Deploy to K8s') {
            steps {
                container('jnlp') {
                    script {
                        sh """
                            echo "Deploying to Kubernetes..."
                            kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                            kubectl apply -f k8s-deploymentservice.yml -n ${K8S_NAMESPACE}
                            kubectl set image deployment/nodeapp-deployment \\
                                nodeapp-container=${DOCKER_IMAGE}:${DOCKER_TAG} \\
                                -n ${K8S_NAMESPACE}
                            kubectl rollout status deployment/nodeapp-deployment -n ${K8S_NAMESPACE} --timeout=300s
                            kubectl get all -n ${K8S_NAMESPACE}
                        """
                    }
                }
            }
        }
    }
}