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

        # Override CMD (not entrypoint) to wrap the runner with a 1-hour timeout,
        # as a safety net in case the runner hangs or never picks up a job.
        # Note: overriding entrypoint would drop the image's CMD, causing
        # entrypoint.sh to exit immediately after configuration without starting the listener.
        command = "/usr/bin/timeout"
        args    = ["3600", "./bin/Runner.Listener", "run", "--startuptype", "service"]

        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock",
          "/usr/bin/nomad:/usr/bin/nomad:ro",
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
NOMAD_ADDR=http://{{ env "attr.unique.network.ip-address" }}:4646
EOF
        destination = "local/env"
        env         = true
      }

      resources {
        cpu        = 400
        memory     = 512
        memory_max = 1024
      }
    }
  }
}
