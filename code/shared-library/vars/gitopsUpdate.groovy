def call(Map args) {
    String repo = args.repo
    String branch = args.get('branch', 'main')
    String valuesFile = args.valuesFile
    String tag = args.tag
    String credentialsId = args.get('credentialsId', 'github-creds')

    withCredentials([usernamePassword(credentialsId: credentialsId, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
        sh """
            rm -rf gitops-work
            git clone --branch ${branch} https://\${GIT_USER}:\${GIT_TOKEN}@${repo} gitops-work
            cd gitops-work
            sed -i 's/^  tag: .*/  tag: "${tag}"/' ${valuesFile}
            git config user.name jenkins
            git config user.email jenkins@builder.local
            git add ${valuesFile}
            git commit -m 'gitops: image tag ${tag}' || echo 'nothing to commit'
            git push origin ${branch}
        """
    }
}
