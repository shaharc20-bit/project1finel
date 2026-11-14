pipeline {
    agent any

    environment {
        IMAGE = 'shaharc20/flask-aws-monitor'
        REPO = 'github.com/shaharc20-bit/project1finel.git'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    // Tag = last commit that changed the app or the chart.
                    // A build on a Jenkins "Deploy" commit gets the same tag, so gitops/ does not change (no loop).
                    env.TAG = sh(returnStdout: true, script: 'git log -1 --format=%h -- app helm').trim()
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

        stage('Push to gitops/') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                    sh '''
                        rm -rf deploy-repo
                        git clone "https://$GIT_USER:$GIT_TOKEN@$REPO" deploy-repo
                        mkdir -p deploy-repo/gitops/flask-app
                        cp flask-app.yaml deploy-repo/gitops/flask-app/flask-app.yaml
                        cd deploy-repo
                        git config user.name "jenkins"
                        git config user.email "jenkins@aws-lab"
                        git add gitops
                        if git diff --cached --quiet; then
                            echo "gitops/ already has $IMAGE:$TAG"
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
            sh 'rm -rf deploy-repo'
        }
    }
}
