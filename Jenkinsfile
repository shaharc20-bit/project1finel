// Pipeline: checkout -> PARALLEL lint + security scan -> docker build -> push to Docker Hub
//           -> helm template -> push to gitops/ (Argo CD deploys from there).
// MOCK_CHECKS=true prints "MOCK: ..." instead of running the lint/scan tools (allowed by the exam).
// The tools run in throw-away containers; --volumes-from jenkins gives them the Jenkins workspace
// (Jenkins runs in the container named "jenkins" and uses the host docker socket).

def check(String name, String cmd) {
    if (params.MOCK_CHECKS) {
        echo "MOCK: ${name}"
    } else {
        sh cmd
    }
}

pipeline {
    agent any

    options {
        timestamps()
    }

    parameters {
        booleanParam(name: 'MOCK_CHECKS', defaultValue: false, description: 'Mock the lint and security tools (print instead of run)')
    }

    environment {
        RUN = 'docker run --rm --volumes-from jenkins'
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

        stage('Parallel Checks') {
            parallel {
                stage('Lint: flake8 (Python)') {
                    steps {
                        script {
                            check('flake8 app', '$RUN -w $WORKSPACE/app python:3.12-slim sh -c "pip install -q --no-cache-dir flake8 && flake8 ."')
                        }
                    }
                }
                stage('Lint: hadolint (Dockerfile)') {
                    steps {
                        script {
                            check('hadolint app/Dockerfile', 'docker run --rm -i hadolint/hadolint < app/Dockerfile')
                        }
                    }
                }
                stage('Lint: shellcheck (Shell)') {
                    steps {
                        script {
                            check('shellcheck *.sh', '''
                                files=$(find . -name "*.sh" -not -path "./.git/*")
                                if [ -n "$files" ]; then
                                    $RUN -w $WORKSPACE koalaman/shellcheck:stable $files
                                else
                                    echo "No shell scripts to check"
                                fi
                            ''')
                        }
                    }
                }
                stage('Lint: helm') {
                    steps {
                        script {
                            check('helm lint', '$RUN -w $WORKSPACE alpine/helm:3.16.2 lint helm/flask-app')
                        }
                    }
                }
                stage('Security: bandit (Python)') {
                    steps {
                        script {
                            // B104 = bind to 0.0.0.0, which is required inside a container
                            check('bandit app', '$RUN -w $WORKSPACE/app python:3.12-slim sh -c "pip install -q --no-cache-dir bandit && bandit -r . -x ./tests -ll -s B104"')
                        }
                    }
                }
                stage('Security: trivy fs (deps, secrets, config)') {
                    steps {
                        script {
                            check('trivy fs', '$RUN -v trivy-cache:/root/.cache aquasec/trivy:latest fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --exit-code 0 $WORKSPACE')
                        }
                    }
                }
                stage('Unit tests (pytest + moto)') {
                    steps {
                        script {
                            check('pytest app/tests', '$RUN -e PYTHONDONTWRITEBYTECODE=1 -w $WORKSPACE/app python:3.12-slim sh -c "pip install -q --no-cache-dir -r requirements-dev.txt && python -m pytest -q -p no:cacheprovider tests"')
                        }
                    }
                }
            }
        }

        stage('Build image') {
            steps {
                sh 'docker build -t $IMAGE:$TAG app'
            }
        }

        stage('Scan image (trivy)') {
            steps {
                script {
                    check('trivy image', 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache aquasec/trivy:latest image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 0 $IMAGE:$TAG')
                }
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
