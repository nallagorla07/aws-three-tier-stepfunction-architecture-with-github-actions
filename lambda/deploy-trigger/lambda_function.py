"""
deploy-trigger Lambda
---------------------
Invoked by Step Function with:
  { "tier": "app|web", "action": "deploy|health_check" }

deploy     → refreshes the Auto Scaling Group instances via SSM Run Command
health_check → polls ASG instance health and returns pass/fail
"""

import json
import os
import time
import logging

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ssm    = boto3.client("ssm",            region_name=os.environ["REGION"])
asg    = boto3.client("autoscaling",    region_name=os.environ["REGION"])
ec2    = boto3.client("ec2",            region_name=os.environ["REGION"])

WEB_ASG = os.environ["WEB_ASG_NAME"]
APP_ASG = os.environ["APP_ASG_NAME"]
S3_BUCKET = os.environ["S3_BUCKET"]


def get_instance_ids(asg_name: str) -> list[str]:
    resp = asg.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])
    groups = resp["AutoScalingGroups"]
    if not groups:
        raise ValueError(f"ASG not found: {asg_name}")
    return [
        i["InstanceId"]
        for i in groups[0]["Instances"]
        if i["LifecycleState"] == "InService"
    ]


def run_ssm_command(instance_ids: list[str], script: str, comment: str) -> str:
    if not instance_ids:
        raise RuntimeError("No InService instances found — cannot deploy")

    resp = ssm.send_command(
        InstanceIds=instance_ids,
        DocumentName="AWS-RunShellScript",
        Parameters={"commands": [script]},
        Comment=comment,
        TimeoutSeconds=300,
    )
    return resp["Command"]["CommandId"]


def wait_for_ssm(command_id: str, instance_ids: list[str], timeout: int = 240):
    deadline = time.time() + timeout
    while time.time() < deadline:
        statuses = []
        for iid in instance_ids:
            try:
                inv = ssm.get_command_invocation(CommandId=command_id, InstanceId=iid)
                statuses.append(inv["StatusDetails"])
            except ssm.exceptions.InvocationDoesNotExist:
                statuses.append("Pending")

        logger.info("SSM command statuses: %s", statuses)

        if all(s in ("Success",) for s in statuses):
            return
        if any(s in ("Failed", "Cancelled", "TimedOut") for s in statuses):
            raise RuntimeError(f"SSM command failed: {statuses}")

        time.sleep(15)

    raise TimeoutError("SSM command did not complete in time")


def deploy(tier: str):
    asg_name = APP_ASG if tier == "app" else WEB_ASG
    artifact  = f"{tier}-tier.zip"
    deploy_path = "/opt/app" if tier == "app" else "/usr/share/nginx/html"

    script = (
        f"aws s3 cp s3://{S3_BUCKET}/{artifact} /tmp/{artifact} && "
        f"unzip -o /tmp/{artifact} -d {deploy_path} && "
        f"{'systemctl restart app' if tier == 'app' else 'systemctl reload nginx'}"
    )

    instance_ids = get_instance_ids(asg_name)
    logger.info("Deploying %s tier to instances: %s", tier, instance_ids)
    command_id = run_ssm_command(instance_ids, script, f"Deploy {tier} tier")
    wait_for_ssm(command_id, instance_ids)
    logger.info("%s tier deployment complete", tier)


def health_check(tier: str) -> bool:
    asg_name = APP_ASG if tier == "app" else WEB_ASG
    resp = asg.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])
    instances = resp["AutoScalingGroups"][0]["Instances"]

    healthy = [i for i in instances if i["HealthStatus"] == "Healthy"]
    logger.info(
        "Health check %s: %d/%d healthy", tier, len(healthy), len(instances)
    )

    if not healthy:
        raise RuntimeError(f"No healthy instances in {tier} ASG")
    return True


def lambda_handler(event, context):
    tier   = event.get("tier")
    action = event.get("action")

    if tier not in ("app", "web"):
        raise ValueError(f"Unknown tier: {tier}")

    logger.info("Action=%s Tier=%s", action, tier)

    if action == "deploy":
        deploy(tier)
        return {"status": "deployed", "tier": tier}

    if action == "health_check":
        healthy = health_check(tier)
        return {"status": "healthy" if healthy else "unhealthy", "tier": tier}

    raise ValueError(f"Unknown action: {action}")
