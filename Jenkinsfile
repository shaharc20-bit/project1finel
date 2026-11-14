pipeline {
    agent any

    environment {
        IMAGE = 'shaharc20/flask-aws-monitor'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                }
                echo "Image tag: ${env.TAG}"
            }
        }

        stage('Build image') {
            steps {
                sh 'docker build -t $IMAGE:$TAG app'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')]) {
                    sh '''
                        echo "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin
                        docker push $IMAGE:$TAG
                    '''
                }
            }
        }

        stage('Helm template') {
            steps {
                sh '''
                    helm lint helm/flask-app
                    helm template flask-app helm/flask-app --set image.tag=$TAG > k8s/flask-app.yaml
                    git rm -q --ignore-unmatch k8s/deployment.yaml k8s/service.yaml
                    cat k8s/flask-app.yaml
                '''
            }
        }

        stage('Push to GitOps (k8s/)') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                    sh '''
                        git config user.name "jenkins"
                        git config user.email "jenkins@aws-lab"
                        git add k8s
                        git commit -m "Deploy $IMAGE:$TAG"
                        git push "https://$GIT_USER:$GIT_TOKEN@github.com/shaharc20-bit/project1finel.git" HEAD:main
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
    }
}
