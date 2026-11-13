pipeline {
    agent any

    environment {
        IMAGE = 'shaharc20/flask-aws-monitor'
        TAG   = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
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

        stage('Update k8s/deployment.yaml') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                    sh '''
                        git config user.name "jenkins"
                        git config user.email "jenkins@aws-lab"
                        sed -i "s|image: .*|image: $IMAGE:$TAG|" k8s/deployment.yaml
                        git add k8s/deployment.yaml
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
