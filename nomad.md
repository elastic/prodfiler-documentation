# Deploying via Nomad

Below an example Nomad config to deploy the agent on 20% of machines, up to 100 deployments:

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
        image = "optimyze/pf-host-agent:release-beta-1"
        command = "/root/pf-host-agent"
        args = [
          "--collection-agent", "dev.prodfiler.com:10000",
          "--config", "/etc/prodfiler/pf-host-agent.conf",
          "--optimyze-homedir","/opt/optimyze",
          "--project-id","[YYYY]",
          "--secret-token", "[ZZZZ]",
          "-t", "all",
        ]
        privileged = true
        auth {
          username = "optimyzeprodfilerbeta"
          password = "6e40c039-2639-4790-993d-1dd58ce74053"
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

