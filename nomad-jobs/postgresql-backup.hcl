job "postgresql-backup" {
  type = "batch"

  periodic {
    crons            = ["0 0 * * *"]
    prohibit_overlap = true
  }

  group "backup" {
    volume "postgresql-backup" {
      type   = "host"
      source = "postgresql-backup"
    }

    task "pg_dumpall" {
      driver = "docker"

      volume_mount {
        volume      = "postgresql-backup"
        destination = "/backups"
      }

      config {
        image        = "postgres:17"
        network_mode = "host"
        command      = "/bin/sh"
        args         = ["-c", "pg_dumpall -h 127.0.0.1 -U postgres > /backups/all-$(date +%Y%m%d-%H%M%S).sql"]
      }

      template {
        data        = <<EOF
{{ with nomadVar "postgresql-secrets" }}
PGPASSWORD={{ .POSTGRES_PASSWORD }}
{{ end }}
EOF
        destination = "local/secrets.env"
        env         = true
      }

      resources {
        cpu        = 200
        memory     = 128
        memory_max = 256
      }
    }
  }
}
