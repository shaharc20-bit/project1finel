// Security scan helpers (bandit for the Python code, trivy for files and for the image).
def bandit(String appDir) {
    sh "docker run --rm --volumes-from jenkins -w \$WORKSPACE/${appDir} python:3.12-slim sh -c 'pip install -q --no-cache-dir bandit && bandit -r . -x ./tests -ll -s B104'"
}

def trivyFs(String severity = 'HIGH,CRITICAL') {
    sh "docker run --rm --volumes-from jenkins -v trivy-cache:/root/.cache aquasec/trivy:latest fs --scanners vuln,secret,misconfig --severity ${severity} --exit-code 0 \$WORKSPACE"
}

def trivyImage(String image, String severity = 'HIGH,CRITICAL') {
    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache aquasec/trivy:latest image --severity ${severity} --ignore-unfixed --exit-code 0 ${image}"
}
