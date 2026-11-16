# app/ - Flask AWS Monitor

Flask app that lists **EC2 instances, VPCs, Load Balancers and AMIs** (owned by the account) in the region from `AWS_REGION` (default `us-east-1`).
The folder also still holds the earlier prOne app (`one.py`, `templates/`); the Docker image runs `app.py`.

## What was implemented
- `app.py` - the exam app, **with the Section 4 bug fixed**: `vpcs`, `lbs` and `amis` were used but never fetched (`NameError` on `/`). Added `describe_vpcs()`, `describe_load_balancers()`, `describe_images(Owners=["self"])`.
- AWS errors (no credentials, no permission) are shown on the page instead of a 500 error; `/health` is used by the Docker HEALTHCHECK.
- AWS keys come only from environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`); without them boto3 uses the EC2 IAM role.
- `Dockerfile` - multi-stage build (bonus), non-root user, port 5001.
- `docker-compose.yml` - run the app with one command.
- `tests/` - pytest with `moto` (mocked AWS, no real AWS needed).

## Missing / blockers
- Nothing blocking. The first commit of `app.py` is the original exam code (with the bug) on purpose (Section 3: "no need to fix the error at this stage"); the fix is in the next commit.

## Run on the builder EC2
```bash
git clone https://github.com/shaharc20-bit/project1finel.git
cd project1finel/app
export AWS_ACCESS_KEY_ID=...  AWS_SECRET_ACCESS_KEY=...  AWS_REGION=us-east-1   # never commit these
docker compose up -d --build        # or: docker build -t flask-aws-monitor . && docker run -d -p 5001:5001 -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY flask-aws-monitor
curl http://localhost:5001/health
```
Open `http://<builder-public-ip>:5001/`.

## Test
```bash
pip install -r requirements-dev.txt
python -m pytest -q tests
flake8 .
bandit -r . -x ./tests -ll -s B104
```
