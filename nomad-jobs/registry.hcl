job "registry" {
  type = "service"

  constraint {
    attribute = "${attr.unique.hostname}"
    operator  = "regexp"
    value     = "sgp-nomad-core[12]"
  }

  group "registry" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        to = 5000
      }
    }

    service {
      name     = "docker-registry"
      port     = "http"
      provider = "nomad"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.registry.entrypoints=https",
        "traefik.http.routers.registry.rule=Host(`docker-registry.internal`)",
        "traefik.http.routers.registry.tls=true",
      ]

      check {
        type     = "http"
        path     = "/v2/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "registry" {
      driver = "docker"

      config {
        image = "registry:2"
        ports = ["http"]
      }

      template {
        data        = <<EOF
REGISTRY_STORAGE=s3
REGISTRY_STORAGE_S3_REGION=garage
REGISTRY_STORAGE_S3_REGIONENDPOINT=http://{{ env "attr.unique.network.ip-address" }}:3900
REGISTRY_STORAGE_S3_BUCKET=docker-registry
REGISTRY_STORAGE_S3_FORCEPATHSTYLE=true
{{ with nomadVar "garage-auth/registry" }}
REGISTRY_STORAGE_S3_ACCESSKEY={{ .S3_ACCESS_KEY }}
REGISTRY_STORAGE_S3_SECRETKEY={{ .S3_SECRET_KEY }}
{{ end }}
EOF
        destination = "local/secrets.env"
        env         = true
      }

      resources {
        cpu        = 200
        memory     = 256
        memory_max = 512
      }
    }
  }
}
