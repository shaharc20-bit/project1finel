def build(String image, String tag, String context = '.') {
    sh "docker build -t ${image}:${tag} -t ${image}:latest ${context}"
}

def push(String image, String tag, String credentialsId = 'dockerhub-creds') {
    withCredentials([usernamePassword(credentialsId: credentialsId, usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')]) {
        sh 'echo "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin'
        sh "docker push ${image}:${tag}"
        sh "docker push ${image}:latest"
    }
}

def cleanup(String image, String tag) {
    sh "docker logout || true"
    sh "docker image rm ${image}:${tag} || true"
}
