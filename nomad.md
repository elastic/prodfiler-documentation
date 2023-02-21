# Deploying via Nomad

Before installing Prodfiler, verify that your nodes meet the [requirements](README.md#supported-platforms).

## Quick start

Follow the commands you find in the `Project > Instructions` menu in the Prodfiler UI.
You will end up with a configuration for the templates defined in [nomad/prodfiler.nomad](scripts/nomad/prodfiler.nomad). 

## Customizing the configuration

Below is a more complex example of a Nomad configuration to deploy the agent on 20% of machines, 
up to 100 deployments.
You can add customizations to it, but remember to replace the `CAPITALIZED` placeholders with the proper data from the 
deployment instructions in the UI.


```
job "prodfiler-agent" {
  datacenters = ["datacenter"]
  type = "service"

  constraint {
    operator  = "distinct_hosts"
    value     = "true"
  }

  group "prodfiler-agent" {
    count = 100
    spread {
      attribute = "${meta.region}"
      target "eu-central" {
        percent = 20
      }
      target "eu-west" {
        percent = 20
      }
      target "us-west" {
        percent = 20
      }
      target "us-east" {
        percent = 20
      }
      target "us-north" {
        percent = 20
      }
    }
    
    task "prodfiler-agent" {
      driver = "docker"
      config {
        image = "optimyze/pf-host-agent:v2.5.2"
        command = "/root/pf-host-agent"
        args = [
          "-t", "all",
        ]
        privileged = true
        auth {
          username = "optimyzeprodfilerbeta"
          password = "PASSWORD"
        }
        force_pull = true
        pid_mode = "host"
        volumes = [
          "/etc/machine-id:/etc/machine-id",
          "/sys/kernel/debug:/sys/kernel/debug",
          "/var/run/docker.sock:/var/run/docker.sock"
        ]
      }
      volume_mount {
        volume = "optimyze-cache"
        destination = "/var/cache/optimyze"
        read_only = false
      }
      resources {
        memory = 400
      }
      env {
        PRODFILER_PROJECT_ID="PROJECTID"
        PRODFILER_SECRET_TOKEN="SECRETTOKEN"
        PRODFILER_COLLECTION_AGENT="COLLECTIONAGENT"
      }
    }
  }
}
```
