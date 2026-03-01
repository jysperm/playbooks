// Discourse upgrade must be done via ansible (./launcher bootstrap),
// NOT from the admin panel. Admin panel upgrades run migrations but
// don't update the Docker image, causing version mismatch on redeploy.

job "atom-china" {
  type = "service"

  group "discourse" {
    volume "discourse-data" {
      type   = "host"
      source = "discourse-data"
    }

    network {
      port "http" {
        to = 80
      }
    }

    service {
      name     = "atom-china"
      port     = "http"
      provider = "nomad"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.atom-china.entrypoints=https",
        "traefik.http.routers.atom-china.rule=Host(`atom-china.org`)",
        "traefik.http.routers.atom-china.tls=true",
        "traefik.http.routers.atom-china.tls.certresolver=letsencrypt",
      ]
    }

    task "discourse" {
      driver = "docker"

      volume_mount {
        volume      = "discourse-data"
        destination = "/shared"
      }

      config {
        image   = "docker-registry.internal/discourse/atom-china"
        command = "/sbin/boot"
        ports   = ["http"]

        volumes = [
          "/var/discourse/shared/atom-china/log/var-log:/var/log",
        ]
      }

      env {
        DISCOURSE_HOSTNAME         = "atom-china.org"
        DISCOURSE_DEVELOPER_EMAILS = "jysperm@gmail.com"
        DISCOURSE_SMTP_ADDRESS     = "email-smtp.us-east-1.amazonaws.com"
        DISCOURSE_SMTP_PORT        = "587"
        UNICORN_WORKERS            = "1"
      }

      template {
        data        = <<EOF
{{ with nomadVar "discourse-secrets" }}
DISCOURSE_SMTP_USER_NAME={{ .SMTP_USER }}
DISCOURSE_SMTP_PASSWORD={{ .SMTP_PASSWORD }}
{{ end }}
EOF
        destination = "local/secrets.env"
        env         = true
      }

      resources {
        cpu        = 1000
        memory     = 1280
        memory_max = 2048
      }
    }
  }
}
