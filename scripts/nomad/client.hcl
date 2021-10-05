client {
  host_volume "optimyze-cache" {
    path = "/var/cache/optimyze"
    read_only = false
  }
}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
    allow_privileged = true
  }
}
