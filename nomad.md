# Deploying via Nomad

Before installing Prodfiler, verify that your nodes meet the [requirements](README.md#supported-platforms).
Below is an example Nomad config that can be used to deploy the agent on 20% of machines, up to 100 deployments.
Replace the `task.config.auth.password` placeholder with the token released to you by your Optimyze contact.

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
        image = "optimyze/pf-host-agent:release-beta-8"
        command = "/root/pf-host-agent"
        args = [
          "--collection-agent", "data.try.prodfiler.com:443",
          "--config", "/etc/prodfiler/pf-host-agent.conf",
          "--optimyze-homedir","/opt/optimyze",
          "--project-id","[YYYY]",
          "--secret-token", "[ZZZZ]",
          "-t", "all",
        ]
        privileged = true
        auth {
          username = "optimyzeprodfilerbeta"
          password = "<PASSWORD>"
        }
        force_pull = true
        pid_mode = "host"
        volumes = [
          "/etc/machine-id:/etc/machine-id",
          "/sys/kernel/debug:/sys/kernel/debug",
          "/dev/null:/etc/prodfiler/pf-host-agent.conf"
        ]
      }
      resources {
        memory = 512
      }
      env {
        GODEBUG="madvdontneed=1"
      }
    }
  }
}
```
