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
        memory: "256Mi"
        cpu: "250m"
      limits:
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
      limits:
        memory: "512Mi"
        cpu: "500m"
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ['/bin/sh', '-c', 'cat && tail -f /dev/null']
    tty: true
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"
      limits:
        memory: "512Mi"
        cpu: "500m"
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
        stage('Wait for Agent Initialization') {
            steps {
                script {
                    echo "Waiting for agent containers to be ready..."
                    sleep 30
                }
            }
        }
        
        stage('Checkout Code') {
            steps {
                container('jnlp') {
                    git branch: 'master', url: 'https://github.com/HadilFares/ci-cd-pipeline-with-jenkins-docker-k8s.git'
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
                                echo \"Logging into Docker Hub...\"
                                echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                                echo \"Pushing image to Docker Hub...\"
                                docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                                echo \"Image pushed successfully!\"
                            """
                        }
                    }
                }
            }
        }
        
        stage('Deploy to K8s') {
            steps {
                container('kubectl') {
                    script {
                        echo "Testing kubectl container..."
                        sh "kubectl version --client"
                        
                        echo "Deploying to Kubernetes..."
                        sh """
                            # Test Kubernetes access
                            echo "Kubernetes access test:"
                            kubectl cluster-info
                            kubectl get nodes
                            
                            # Create namespace if it doesn't exist
                            kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                            
                            # Apply configuration
                            echo "Applying Kubernetes configuration..."
                            kubectl apply -f k8s-deploymentservice.yml -n ${K8S_NAMESPACE}
                            
                            # Update image
                            echo "Updating deployment image..."
                            kubectl set image deployment/nodeapp-deployment \\
                                nodeapp-container=${DOCKER_IMAGE}:${DOCKER_TAG} \\
                                -n ${K8S_NAMESPACE}
                            
                            # Wait for rollout
                            echo "Waiting for deployment rollout..."
                            kubectl rollout status deployment/nodeapp-deployment \\
                                -n ${K8S_NAMESPACE} --timeout=300s
                            
                            echo "Deployment successful!"
                            
                            # Show results
                            echo "Deployment status:"
                            kubectl get pods,services,deployments -n ${K8S_NAMESPACE}
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "CI/CD Pipeline COMPLETED SUCCESSFULLY!"
            echo "Application deployed to Kubernetes!"
        }
        failure {
            echo "CI/CD Pipeline FAILED!"
        }
        always {
            echo "Pipeline execution completed"
        }
    }
}