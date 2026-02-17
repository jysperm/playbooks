job "postgresql" {
  type = "service"

  group "postgresql" {
    count = 1

    volume "postgresql-data" {
      type   = "host"
      source = "postgresql-data"
    }

    network {
      port "postgresql" { static = 5432 }
    }

    task "postgresql" {
      driver = "docker"

      volume_mount {
        volume      = "postgresql-data"
        destination = "/var/lib/postgresql/data"
      }

      config {
        image        = "postgres:17"
        ports        = ["postgresql"]
        network_mode = "host"
      }

      template {
        data        = <<EOF
{{ with nomadVar "postgresql-secrets" }}
POSTGRES_PASSWORD={{ .POSTGRES_PASSWORD }}
{{ end }}
EOF
        destination = "local/secrets.env"
        env         = true
      }

      resources {
        cpu        = 400
        memory     = 256
        memory_max = 1024
      }
    }
  }
}
