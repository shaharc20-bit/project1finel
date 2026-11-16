// Run pytest (with moto = mocked AWS) in a container.
def call(String appDir) {
    sh "docker run --rm -e PYTHONDONTWRITEBYTECODE=1 --volumes-from jenkins -w \$WORKSPACE/${appDir} python:3.12-slim sh -c 'pip install -q --no-cache-dir -r requirements-dev.txt && python -m pytest -q -p no:cacheprovider tests'"
}
