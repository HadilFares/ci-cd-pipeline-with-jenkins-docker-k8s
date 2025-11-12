pipeline {
    agent {
        kubernetes {
            label 'ci-agent'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    env:
    - name: JENKINS_URL
      value: "http://192.168.49.3:8080"
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
  - name: docker
    image: docker:latest
    command: ['cat']
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ['cat']
    tty: true
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
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
        stage('Wait for Agent') {
            steps {
                script {
                    echo "Waiting for agent to be fully ready..."
                    sleep 10
                }
            }
        }
        
        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/HadilFares/ci-cd-pipeline-with-jenkins-docker-k8s.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    script {
                        echo "Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker images
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
                            echo "Logging into Docker Hub..."
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            echo " Pushing image to Docker Hub..."
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            echo " Image pushed successfully!"
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
                        echo "Deploying to Kubernetes..."
                        sh """
                        # Vérifier l'accès Kubernetes
                        echo " Kubernetes access test:"
                        kubectl cluster-info
                        kubectl get nodes
                        # Appliquer la configuration
                        echo "Applying Kubernetes configuration..."
                        kubectl apply -f k8s-deploymentservice.yml --namespace=${K8S_NAMESPACE}
                        
                        # Mettre à jour l'image
                        echo "Updating deployment image..."
                        kubectl set image deployment/nodeapp-deployment \\
                          nodeapp-container=${DOCKER_IMAGE}:${DOCKER_TAG} \\
                          --namespace=${K8S_NAMESPACE}
                        
                        # Vérifier le déploiement
                        echo "Waiting for deployment rollout..."
                        kubectl rollout status deployment/nodeapp-deployment \\
                          --namespace=${K8S_NAMESPACE} --timeout=300s
                        
                        echo "Deployment successful!"
                        
                        # Afficher les résultats
                        echo "Deployment status:"
                        kubectl get pods,services,deployments --namespace=${K8S_NAMESPACE}
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
            script {
                // Debug en cas d'échec
                sh '''
                echo "Debug information:"
                echo "Workspace files:"
                ls -la
                echo "Docker images:"
                docker images || true
                '''
            }
        }
        always {
            echo " Pipeline execution completed"
        }
    }
}