def bandit(String appDir) {
    sh "docker run --rm -v \"\$WORKSPACE\":/src -w /src/${appDir} python:3.12-slim sh -c 'pip install -q bandit && bandit -r . -x ./tests -ll'"
}

def trivyFs(String path = '.', String severity = 'HIGH,CRITICAL') {
    sh "docker run --rm -v \"\$WORKSPACE\":/src -v trivy-cache:/root/.cache/ aquasec/trivy:latest fs --scanners vuln,secret,misconfig --severity ${severity} --exit-code 0 /src/${path}"
}

def trivyImage(String image, String severity = 'HIGH,CRITICAL') {
    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/ aquasec/trivy:latest image --severity ${severity} --ignore-unfixed --exit-code 0 ${image}"
}
