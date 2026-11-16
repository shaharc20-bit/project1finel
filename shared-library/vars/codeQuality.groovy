// Lint helpers. The tools run in throw-away containers that share the Jenkins workspace
// (--volumes-from jenkins: Jenkins itself runs in the container named "jenkins").
def flake8(String appDir) {
    sh "docker run --rm --volumes-from jenkins -w \$WORKSPACE/${appDir} python:3.12-slim sh -c 'pip install -q --no-cache-dir flake8 && flake8 .'"
}

def hadolint(String dockerfile) {
    sh "docker run --rm -i hadolint/hadolint < ${dockerfile}"
}

def shellcheck(String path = '.') {
    def files = sh(script: "find ${path} -name '*.sh' -not -path '*/.git/*'", returnStdout: true).trim()
    if (files) {
        sh "docker run --rm --volumes-from jenkins -w \$WORKSPACE koalaman/shellcheck:stable ${files.replace('\n', ' ')}"
    } else {
        echo 'No shell scripts to check'
    }
}

def helmLint(String chartDir) {
    sh "docker run --rm --volumes-from jenkins -w \$WORKSPACE alpine/helm:3.16.2 lint ${chartDir}"
}
