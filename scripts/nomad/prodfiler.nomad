job "prodfiler-agent" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
    operator  = "distinct_hosts"
    value     = "true"
  }
  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

  group "prodfiler-agent" {

    volume "optimyze-cache" {
      type = "host"
      read_only = false
      source = "optimyze-cache"
    }

    task "prodfiler-agent" {
      driver = "docker"
      config {
        image = "optimyze/pf-host-agent:RELEASE"
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
