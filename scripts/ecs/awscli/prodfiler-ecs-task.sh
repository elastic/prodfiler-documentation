#!/usr/bin/env bash

set -euo pipefail

function usage() {
    echo "ECS Prodfiler Task setup"
    echo ""
    echo "This script sets up a DAEMON task for Prodfiler in an already existing cluster."
    echo "You will need several ECS permissions for the script to complete successfully... see the README for more details."
    echo "Dependencies: aws, jq, mktemp"
    echo ""
    echo "Example usage (please note arg=value syntax is not supported):"
    echo "$0 --cluster-arn foo --collection-agent app.prodfiler.com:10000 --project-id 123 --secret-token aaabbbcccddd123 --version v1.2.3 --tracers (all|native) --secret-token foobar123"
}

if [ "$#" -ne 12 ]; then usage; exit 1; fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage; exit 0 ;;
        --cluster-arn) clusterArn="$2"; shift ;;
        --collection-agent) collectionAgentHostPort="$2"; shift ;;
        --project-id) projectId="$2"; shift ;;
        --version) version="$2"; shift ;;
        --tracers) tracers="$2"; shift ;;
        --secret-token) secretToken="$2"; shift ;;
        *) echo "unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

export AWS_PAGER=cat

echo "get the pullSecret ARN"
pullSecretArn=$(aws secretsmanager list-secrets --filter "Key=name,Values=optimyze/prodfiler/pullSecret" | jq -r '.SecretList[0].ARN')

echo "get the task execution role ARN"
ecsRoleArn=$(aws iam get-role --role-name ecsProdfilerTaskExecutionRole | jq -r '.Role.Arn')

echo "building temporary file to hold ECS task cli-input-json"
tmpFile=$(mktemp -p $PWD -t task_XXX.json)
awk '{ gsub("_pullSecretArn_",p); gsub("_ecsRoleArn_",e); gsub("_collectionAgentHostPort_",c); gsub("_projectId_",pr); gsub("_version_",v); gsub("_tracers_",t); gsub("_secretToken_",s);print }' \
  p="$pullSecretArn" e="$ecsRoleArn" c="$collectionAgentHostPort" pr="$projectId" v="$version" t="$tracers" s="$secretToken"\
  task.json.template > $tmpFile

echo "registering a Prodfiler task inside cluster $clusterArn"
aws ecs register-task-definition --cli-input-json file://$tmpFile

echo "creating Prodfiler DAEMON service inside cluster $clusterArn"
aws ecs create-service --cluster $clusterArn --service-name optimyze-prodfiler \
  --task-definition optimyze-prodfiler --launch-type EC2 --scheduling-strategy DAEMON

echo "success!"
