pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'hadilfares/nodeapp'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        K8S_NAMESPACE = 'default'
    }
    

    stage('Install kubectl') {
    steps {
        script {
            sh '''
            # Vérifier si kubectl est déjà installé
            if ! command -v kubectl &> /dev/null; then
                echo "📦 Installing kubectl..."
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                chmod +x kubectl
                sudo mv kubectl /usr/local/bin/
            else
                echo "✅ kubectl already installed"
            fi
            
            kubectl version --client
            '''
        }
    }
}
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/HadilFares/ci-cd-pipeline-with-jenkins-docker-k8s.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🔄 Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-cred',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                    }
                    
                    echo "📤 Pushing image to Docker Hub..."
                    sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
        
        stage('Deploy to K8s') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'kubernetes', variable: 'KUBECONFIG')]) {
                        sh """
                        export KUBECONFIG=\$KUBECONFIG
                        
                        echo "🚀 Deploying to Kubernetes..."
                        
                        # Appliquer la configuration K8s
                        kubectl apply -f k8s-deploymentservice.yml --namespace=${K8S_NAMESPACE}
                        
                        # Mettre à jour l'image
                        kubectl set image deployment/nodeapp-deployment \
                        nodeapp-container=${DOCKER_IMAGE}:${DOCKER_TAG} \
                        --namespace=${K8S_NAMESPACE} --record=true
                        
                        # Attendre le déploiement
                        kubectl rollout status deployment/nodeapp-deployment \
                        --namespace=${K8S_NAMESPACE} --timeout=300s
                        
                        echo "✅ Deployment successful!"
                        
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
            echo "🎉 CI/CD Pipeline COMPLETED SUCCESSFULLY!"
            sh """
            echo "📊 Status:"
            kubectl get pods --namespace=${K8S_NAMESPACE}
            kubectl get services --namespace=${K8S_NAMESPACE}
            """
        }
        failure {
            echo "❌ CI/CD Pipeline FAILED!"
        }
    }
}
// ⚠️ SUPPRIME la parenthèse fermante en trop à la fin !