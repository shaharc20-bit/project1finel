import importlib
import os

import boto3
import pytest
from moto import mock_aws

os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_REGION"] = "us-east-1"
os.environ.pop("AWS_SESSION_TOKEN", None)
os.environ.pop("AWS_ENDPOINT_URL", None)


@pytest.fixture
def client():
    with mock_aws():
        ec2 = boto3.client("ec2", region_name="us-east-1")
        elb = boto3.client("elbv2", region_name="us-east-1")

        vpc = ec2.describe_vpcs(Filters=[{"Name": "is-default", "Values": ["true"]}])["Vpcs"][0]
        subnets = ec2.describe_subnets(Filters=[{"Name": "vpc-id", "Values": [vpc["VpcId"]]}])["Subnets"]

        base_ami = ec2.describe_images(Owners=["amazon"])["Images"][0]["ImageId"]
        instance = ec2.run_instances(ImageId=base_ami, MinCount=1, MaxCount=1, InstanceType="t3.medium")["Instances"][0]
        ami = ec2.create_image(InstanceId=instance["InstanceId"], Name="test-ec2-image")

        lb = elb.create_load_balancer(Name="test-alb", Subnets=[s["SubnetId"] for s in subnets[:2]])["LoadBalancers"][0]

        import app as app_module
        importlib.reload(app_module)
        app_module.app.config["TESTING"] = True

        with app_module.app.test_client() as c:
            c.expected = {
                "vpc": vpc["VpcId"],
                "cidr": vpc["CidrBlock"],
                "instance": instance["InstanceId"],
                "ami": ami["ImageId"],
                "lb": lb["LoadBalancerName"],
                "lb_dns": lb["DNSName"],
            }
            yield c


def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.get_json() == {"status": "ok"}


def test_home_lists_all_resources(client):
    res = client.get("/")
    assert res.status_code == 200
    html = res.get_data(as_text=True)
    for value in client.expected.values():
        assert value in html
    assert "test-ec2-image" in html


def test_only_own_amis_are_listed(client):
    html = client.get("/").get_data(as_text=True)
    assert html.count("<td>ami-") == 1
