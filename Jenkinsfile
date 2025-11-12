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
        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/HadilFares/ci-cd-pipeline-with-jenkins-docker-k8s.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    script {
                        echo "🔄 Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
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
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            echo "Pushing image to Docker Hub..."
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
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
                        echo " Deploying to Kubernetes..."
                        sh """
                        # Vérifier l'accès Kubernetes
                        kubectl cluster-info
                        kubectl get nodes
                        
                        # Appliquer la configuration K8s
                        kubectl apply -f k8s-deploymentservice.yml --namespace=${K8S_NAMESPACE}
                        
                        # Mettre à jour l'image
                        kubectl set image deployment/nodeapp-deployment \\
                        nodeapp-container=${DOCKER_IMAGE}:${DOCKER_TAG} \\
                        --namespace=${K8S_NAMESPACE} --record=true
                        
                        # Attendre le déploiement
                        kubectl rollout status deployment/nodeapp-deployment \\
                        --namespace=${K8S_NAMESPACE} --timeout=300s
                        
                        echo "Deployment successful!"
                        
                        # Afficher les infos
                        kubectl get pods --namespace=${K8S_NAMESPACE}
                        kubectl get services --namespace=${K8S_NAMESPACE}
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo " CI/CD Pipeline COMPLETED SUCCESSFULLY!"
            echo " Application deployed to Kubernetes!"
        }
        failure {
            echo " CI/CD Pipeline FAILED!"
        }
    }
}