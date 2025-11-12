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
    env:
    - name: JENKINS_URL
      value: "http://192.168.49.3:8080"
  - name: docker
    image: docker:latest
    command: ['cat']
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ['cat']
    tty: true
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
        WORKSPACE_DIR = 'kubernetes Jenkins Deployment'
    }
    
    stages {
        stage('Navigate to Workspace') {
            steps {
                script {
                    echo "Navigating to workspace directory: ${WORKSPACE_DIR}"
                    dir("${WORKSPACE_DIR}") {
                        sh '''
                        echo "=== CURRENT DIRECTORY ==="
                        pwd
                        ls -la
                        echo "Now in the correct directory with all files!"
                        '''
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    container('docker') {
                        script {
                            echo "Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                            sh """
                            # Vérifier les fichiers
                            ls -la
                            echo "Dockerfile content:"
                            cat dockerfile
                            
                            # Builder l'image
                            docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                            docker images | grep ${DOCKER_IMAGE}
                            """
                        }
                    }
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    container('docker') {
                        script {
                            withCredentials([usernamePassword(
                                credentialsId: 'dockerhublogin',
                                usernameVariable: 'DOCKER_USER',
                                passwordVariable: 'DOCKER_PASS'
                            )]) {
                                sh """
                                echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                                echo " Pushing ${DOCKER_IMAGE}:${DOCKER_TAG} to Docker Hub..."
                                docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                                echo "Image pushed successfully!"
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Deploy to K8s') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    container('kubectl') {
                        script {
                            echo " Deploying to Kubernetes..."
                            sh """
                            # Vérifier les fichiers
                            echo "=== DEPLOYMENT FILES ==="
                            pwd
                            ls -la *.yml
                            cat k8s-deploymentservice.yml
                            
                            # Déployer
                            kubectl apply -f k8s-deploymentservice.yml --namespace=${K8S_NAMESPACE}
                            kubectl set image deployment/nodeapp-deployment \\
                              nodeapp-container=${DOCKER_IMAGE}:${DOCKER_TAG} \\
                              --namespace=${K8S_NAMESPACE}
                            kubectl rollout status deployment/nodeapp-deployment --namespace=${K8S_NAMESPACE}
                            
                            echo " Deployment successful!"
                            kubectl get pods,svc,deployments --namespace=${K8S_NAMESPACE}
                            """
                        }
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo " CI/CD Pipeline COMPLETED SUCCESSFULLY!"
        }
        failure {
            echo "CI/CD Pipeline FAILED!"
        }
    }
}