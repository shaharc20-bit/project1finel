def call(String appDir) {
    sh "docker run --rm -e PYTHONDONTWRITEBYTECODE=1 -v \"\$WORKSPACE\":/src -w /src/${appDir} python:3.12-slim sh -c 'pip install -q -r requirements-dev.txt && python -m pytest -q -p no:cacheprovider tests'"
}
