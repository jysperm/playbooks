job "traefik" {
  type      = "system"
  node_pool = "all"

  group "traefik" {
    network {
      mode = "host"

      port "http"  { static = 80 }
      port "https" { static = 443 }
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v3.6"
        network_mode = "host"

        # TODO: May move to JuiceFS for shared cert storage across nodes.
        # Traefik has no file locking on acme.json, but write frequency is
        # extremely low (only on cert issuance/renewal), so the risk of
        # concurrent write corruption is acceptable.
        volumes = [
          "/var/lib/traefik:/var/lib/traefik",
        ]

        args = [
          "--providers.nomad=true",
          "--providers.nomad.endpoint.address=http://127.0.0.1:4646",
          "--providers.nomad.exposedByDefault=false",

          "--entrypoints.http.address=:80",
          "--entrypoints.https.address=:443",
          "--entrypoints.http.http.redirections.entryPoint.to=https",
          # Lower redirect priority so internal services can optionally define
          # routers on the http entrypoint without being redirected.
          "--entrypoints.http.http.redirections.entryPoint.priority=1",

          "--certificatesresolvers.letsencrypt.acme.httpchallenge=true",
          "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=http",
          "--certificatesresolvers.letsencrypt.acme.email=jysperm@gmail.com",
          "--certificatesresolvers.letsencrypt.acme.storage=/var/lib/traefik/acme.json",

          "--providers.file.directory=/local/config/",
        ]
      }

      template {
        destination = "local/config/mtls.yml"
        data        = <<-EOF
        tls:
          options:
            mtls:
              clientAuth:
                caFiles:
                  - /local/internal-ca.pem
                clientAuthType: RequireAndVerifyClientCert
        EOF
      }

      template {
        destination = "local/config/nomad-dashboard.yml"
        data        = <<-EOF
        http:
          routers:
            nomad:
              rule: "Host(`nomad.ziting.me`)"
              entrypoints:
                - https
              service: nomad
              tls:
                certResolver: letsencrypt
                options: mtls

          services:
            nomad:
              loadBalancer:
                servers:
                  - url: "http://127.0.0.1:4646"
        EOF
      }

      template {
        destination = "local/internal-ca.pem"
        data        = <<EOF
{{ with nomadVar "traefik-internal-certs" }}{{ .CA_PEM }}{{ end }}
EOF
      }

      resources {
        cpu        = 400 # MHz
        memory     = 256 # MB
        memory_max = 512 # MB
      }
    }
  }
}
