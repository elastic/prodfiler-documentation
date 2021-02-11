#!/usr/bin/env bash

set -o pipefail

function usage() {
    echo "ECS Prodfiler Auth setup"
    echo ""
    echo "This script sets up IAM role for ECS Prodfiler DAEMON task: authentication to private registry and IAM role/policies to consume the secret."
    echo "You will need several IAM and SecretsManager permissions for the script to complete successfully... see the README for more details."
    echo "Dependencies: aws, jq"
    echo ""
    echo "Example usage (please note arg=value syntax is not supported):"
    echo "$0 --username foo --password bar"
}

if [ "$#" -ne 4 ]; then usage; exit 1; fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage; exit 0 ;;
        --username) username="$2"; shift ;;
        --password) password="$2"; shift ;;
        *) echo "unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# disables the less pager
export AWS_PAGER=cat

echo "creating a secret with credentials to pull images"
secretString="{\"username\":\"$username\", \"password\":\"$password\"}"
secretTags="[{\"Key\":\"Scope\",\"Value\":\"profiling\"},{\"Key\":\"Provider\",\"Value\":\"optimyze\"}]"
aws secretsmanager create-secret --name optimyze/prodfiler/pullSecret --secret-string "$secretString" --tags "$secretTags"

read -r -d '' assumeRolePolicy << EOM
{
  "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
EOM

echo "creating an IAM role for ECS Prodfiler tasks"
aws iam create-role --role-name ecsProdfilerTaskExecutionRole --path "/optimyze/prodfiler/" --assume-role-policy-document "$assumeRolePolicy" \
 --description "Enables ECS Prodfiler DAEMON permissions"

read -r -d '' pullPolicy << EOM
{
  "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "secretsmanager:GetSecretValue"
        ],
        "Resource": [
          "arn:aws:secretsmanager:*:*:secret:optimyze/prodfiler/pullSecret*"
        ]
      }
    ]
}
EOM

echo "creating a policy to allow ECS task to consume the image pull secret"
policyArn=$(aws iam create-policy --policy-name AmazonECSAllowPrivateRegistryPullSecrets \
  --path "/optimyze/prodfiler/" --policy-document "$pullPolicy" | jq -r '.Policy.Arn')

echo "attaching the proper policies the the IAM role"
aws iam attach-role-policy --role-name ecsProdfilerTaskExecutionRole \
  --policy-arn  arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

aws iam attach-role-policy --role-name ecsProdfilerTaskExecutionRole \
  --policy-arn "$policyArn"

echo "success!"
