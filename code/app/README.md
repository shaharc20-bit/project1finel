# Flask AWS Monitor

Flask app that lists EC2 instances, VPCs, Load Balancers and AMIs (owned by the account) in the region from `AWS_REGION` (default `us-east-1`).

## Bug fix (Section 4)
`vpcs`, `lbs` and `amis` were used but never fetched, so `/` failed with `NameError: name 'vpcs' is not defined`.
Fixed by adding:
- `ec2_client.describe_vpcs()`
- `elb_client.describe_load_balancers()`
- `ec2_client.describe_images(Owners=["self"])`

Also added `/health` (used by Docker HEALTHCHECK and k8s probes), and `AWS_REGION` / `HOST` / `PORT` / `FLASK_DEBUG` from env.

## Files
- `app.py`, `requirements.txt`
- `Dockerfile` - multi-stage, non-root user, port 5001
- `tests/test_app.py` - pytest + moto (mocked AWS), `requirements-dev.txt`

## Run on the builder
```bash
git clone https://github.com/shaharc20-bit/project1finel.git
cd project1finel/code/app
docker build -t flask-aws-monitor .
docker run -d --name flask-aws-monitor -p 5001:5001 -e AWS_REGION=eu-north-1 flask-aws-monitor
curl http://localhost:5001/health
```
Open `http://<builder-public-ip>:5001/`

AWS access comes from the builder's IAM role (instance profile). Outside EC2 pass `-e AWS_ACCESS_KEY_ID=... -e AWS_SECRET_ACCESS_KEY=...`.

## Tests
```bash
pip install -r requirements-dev.txt
python -m pytest -q tests
flake8 .
bandit -r . -x ./tests -ll
```
