# Prodfiler on ECS

To setup Prodfiler on ECS two scripts should be run on a Linux/Mac (respect the order):
* `prodfiler-ecs-auth.sh`: configures credentials to pull the `optimyze/pf-host-agent` image
and IAM resources to consume the secret
* `prodfiler-ecs-task.sh`: deploys a `DAEMON` task in an already-existing ECS cluster

Before installing Prodfiler, verify that your nodes meet the [support requirements](README.md#supported-platforms).
So far, the default Linux AMI 2 ships with an unsupported Linux kernel version (4.14); check the
[Amazon Linux 2 AMI release notes](https://aws.amazon.com/amazon-linux-2/release-notes/) to verify 
support for the current kernel version.  

## ECS support

Currently Prodfiler is available only on ECS clusters with **EC2 launch type**.
Fargate launch type does not allow deploying `DEAMON` tasks and thus is not an option at the moment.

## IAM Permissions

To run this script we suggest to use AWS credentials with the following policies attached:   

* `arn:aws:iam::aws:policy/SecretsManagerReadWrite`
* `arn:aws:iam::aws:policy/IAMFullAccess`
* `arn:aws:iam::aws:policy/AmazonECS_FullAccess`

## Deploying Prodfiler 

Both scripts are _not_ idempotent so they should be executed from AWS credentials 
with the proper authorizations to manage the impacted resources. If the script fails during the execution,
the resources created so far will have to be deleted manually for the script to succeed on then next run.

Scripts use AWS CLI v2, refer to [the official doc](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
to set it up. 

To see the help message, call the scripts with `-h` or `--help`.

### Authentication and secrets

Use the provided credentials to access the private Docker image as arguments of this script.
Run this command from the root of the `scripts/ecs/awscli` directory:

```bash
./prodfiler-ecs-auth.sh --username optimyzeprodfilerbeta --password 6e40c039-2639-4790-993d-1dd58ce74053
```

It will create the secrets used by the ECS DAEMON task using AWS Secret Manager.

### ECS task

Fetch the `projectID` and `secretToken` values visible in the Prodfiler web UI
when creating a new project.
The values are defined as environment variables in the deployment command visible in the UI,
they are called `PRODFILER_PROJECT_ID` and `PRODFILER_SECRET_TOKEN` respectively.

Run the script:

```bash
./prodfiler-ecs-task.sh --cluster-arn <YOUR_CLUSTER_ARN> \
        --collection-agent "dev.prodfiler.com:10000" \
        --project-id <YOUR_PROJECT_ID>
        --version "release-beta-2"
        --tracers "all"
        --secret-token <YOUR_SECRET_TOKEN>
```
At this point Prodfiler Host Agent should be running in your ECS cluster and you should start seeing data in the UI.
