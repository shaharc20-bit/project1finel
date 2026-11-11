def flake8(String appDir) {
    sh "docker run --rm -v \"\$WORKSPACE\":/src -w /src/${appDir} python:3.12-slim sh -c 'pip install -q flake8 && flake8 .'"
}

def hadolint(String dockerfile) {
    sh "docker run --rm -i hadolint/hadolint < ${dockerfile}"
}

def shellcheck(String path = '.') {
    def files = sh(script: "find ${path} -name '*.sh' -not -path '*/.git/*'", returnStdout: true).trim()
    if (files) {
        sh "docker run --rm -v \"\$WORKSPACE\":/src -w /src koalaman/shellcheck:stable ${files.replace('\n', ' ')}"
    } else {
        echo 'No shell scripts to check'
    }
}
