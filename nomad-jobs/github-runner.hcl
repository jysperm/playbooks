job "github-runner" {
  type = "batch"

  parameterized {
    meta_required = ["REPO_URL"]
  }

  group "runner" {
    task "runner" {
      driver = "docker"

      config {
        image = "myoung34/github-runner:latest"

        entrypoint = ["/bin/bash", "-c", "timeout 3600 /entrypoint.sh"]

        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock",
        ]
      }

      template {
        data        = <<EOF
{{ with nomadVar "github-runner-secrets" }}
ACCESS_TOKEN={{ .GITHUB_PAT }}
{{ end }}
REPO_URL={{ env "NOMAD_META_REPO_URL" }}
RUNNER_SCOPE=repo
EPHEMERAL=true
RUNNER_NAME=nomad-{{ env "NOMAD_ALLOC_ID" }}
LABELS=self-hosted,linux,x64
EOF
        destination = "local/env"
        env         = true
      }

      resources {
        cpu        = 1000
        memory     = 1024
        memory_max = 2048
      }
    }
  }
}
