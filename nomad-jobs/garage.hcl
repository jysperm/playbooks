job "garage" {
  type      = "system"
  node_pool = "all"

  group "garage" {
    network {
      mode = "host"

      port "s3"    { static = 3900 }
      port "rpc"   { static = 3901 }
      port "admin" { static = 3903 }
    }

    update {
      health_check  = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "1m"
    }

    service {
      name     = "garage-s3"
      port     = "s3"
      provider = "nomad"

      check {
        type     = "tcp"
        port     = "s3"
        interval = "5s"
        timeout  = "2s"
      }
    }

    task "garage" {
      driver = "docker"

      config {
        image        = "dxflrs/garage:v2.2.0"
        network_mode = "host"

        volumes = [
          "/var/lib/garage:/var/lib/garage",
          "local/garage.toml:/etc/garage.toml:ro",
        ]
      }

      template {
        data        = <<EOF
metadata_dir = "/var/lib/garage/meta"
data_dir = [ { path = "/var/lib/garage/data", capacity = "10G" } ]

replication_factor = 2
compression_level = 1

{{ with nomadVar "garage-secrets" }}
rpc_secret = "{{ .RPC_SECRET }}"
{{ end }}
rpc_bind_addr = "[::]:3901"
rpc_public_addr = "{{ env "attr.unique.network.ip-address" }}:3901"

[s3_api]
api_bind_addr = "[::]:3900"
s3_region = "garage"

[admin]
api_bind_addr = "127.0.0.1:3903"
EOF
        destination = "local/garage.toml"
      }

      resources {
        cpu        = 200
        memory     = 256
        memory_max = 512
      }
    }
  }
}
