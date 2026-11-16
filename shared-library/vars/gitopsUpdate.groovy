// Set the image tag in a values file of the GitOps folder and push it.
// gitopsUpdate(repo: 'github.com/shaharc20-bit/project1finel.git',
//              file: 'gitops/flask-aws-monitor/dev/values.yaml', tag: 'abc1234')
def call(Map args) {
    String repo = args.repo
    String branch = args.get('branch', 'main')
    String valuesFile = args.file
    String tag = args.tag
    String credentialsId = args.get('credentialsId', 'github')

    withCredentials([usernamePassword(credentialsId: credentialsId, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
        sh """
            rm -rf gitops-work
            git clone --branch ${branch} https://\${GIT_USER}:\${GIT_TOKEN}@${repo} gitops-work
            cd gitops-work
            sed -i 's|^  tag: .*|  tag: "${tag}"|' ${valuesFile}
            git config user.name jenkins
            git config user.email jenkins@builder.local
            git add ${valuesFile}
            git commit -m 'Deploy ${tag} (${valuesFile})' || echo 'nothing to commit'
            git push origin ${branch}
        """
    }
}
