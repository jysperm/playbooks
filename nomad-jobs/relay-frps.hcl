#jinja2: variable_start_string: '[%', variable_end_string: '%]'
job "relay-frps" {
  type      = "system"
  node_pool = "relay"

  group "frps" {
    network {
      mode = "host"

      port "frp" { static = 7000 }
    }

    service {
      name     = "relay-frps"
      port     = "frp"
      provider = "nomad"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "frps" {
      driver = "docker"

      config {
        image        = "ghcr.io/fatedier/frps:v0.68.1"
        network_mode = "host"

        args = ["-c", "/local/frps.toml"]
      }

      template {
        destination = "local/frps.toml"
        data        = <<EOF
bindPort = 7000
kcpBindPort = 7000
auth.method = "token"
{{ with nomadVar "relay-frps-secrets" }}
auth.token = "{{ .TOKEN }}"
{{ end }}
EOF
      }

      resources {
        cpu        = 200 # MHz
        memory     = 256 # MB
        memory_max = 512 # MB
      }
    }
  }
}
