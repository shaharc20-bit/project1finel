pipeline {
    agent any

    environment {
        IMAGE = 'shaharc20/flask-aws-monitor'
        GITOPS_REPO = 'github.com/shaharc20-bit/project1-gitops.git'
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
                    helm template flask-app helm/flask-app --set image.tag=$TAG > flask-app.yaml
                    cat flask-app.yaml
                '''
            }
        }

        stage('Push to GitOps repo') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                    sh '''
                        rm -rf gitops
                        git clone "https://$GIT_USER:$GIT_TOKEN@$GITOPS_REPO" gitops
                        mkdir -p gitops/flask-app
                        cp flask-app.yaml gitops/flask-app/flask-app.yaml
                        cd gitops
                        git config user.name "jenkins"
                        git config user.email "jenkins@aws-lab"
                        git add flask-app
                        if git diff --cached --quiet; then
                            echo "GitOps repo already has $IMAGE:$TAG"
                            exit 0
                        fi
                        git commit -m "Deploy $IMAGE:$TAG"
                        git push origin HEAD:main
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
            sh 'rm -rf gitops'
        }
    }
}
