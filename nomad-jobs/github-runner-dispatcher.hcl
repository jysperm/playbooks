job "github-runner-dispatcher" {
  type = "service"

  group "dispatcher" {
    count = 1

    network {
      port "http" {}
    }

    service {
      name     = "github-runner-dispatcher"
      port     = "http"
      provider = "nomad"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.github-runner-dispatcher.rule=Host(`github-runner.ziting.me`)",
        "traefik.http.routers.github-runner-dispatcher.entrypoints=https",
        "traefik.http.routers.github-runner-dispatcher.tls=true",
        "traefik.http.routers.github-runner-dispatcher.tls.certresolver=letsencrypt",
      ]

      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "dispatcher" {
      driver = "docker"

      config {
        image   = "node:22-slim"
        ports   = ["http"]
        command = "node"
        args    = ["local/dispatcher.js"]
      }

      template {
        data        = <<EOF
{{ with nomadVar "github-runner-secrets" }}
WEBHOOK_SECRET={{ .WEBHOOK_SECRET }}
{{ end }}
NOMAD_ADDR=http://{{ env "NOMAD_IP_http" }}:4646
PORT={{ env "NOMAD_PORT_http" }}
EOF
        destination = "local/env"
        env         = true
      }

      template {
        data        = <<JSEOF
const http = require("http");
const crypto = require("crypto");

const PORT = process.env.PORT || 8080;
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET;
const NOMAD_ADDR = process.env.NOMAD_ADDR;

function verifySignature(payload, signature) {
  if (!signature) return false;
  const expected = "sha256=" + crypto.createHmac("sha256", WEBHOOK_SECRET).update(payload).digest("hex");
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
}

async function dispatchRunner(repoUrl) {
  const res = await fetch(`$${NOMAD_ADDR}/v1/job/github-runner/dispatch`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ Meta: { REPO_URL: repoUrl } }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Nomad dispatch failed ($${res.status}): $${body}`);
  }

  return await res.json();
}

const server = http.createServer((req, res) => {
  if (req.method === "GET" && req.url === "/") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("github-runner-dispatcher is running\n");
    return;
  }

  if (req.method !== "POST" || req.url !== "/") {
    res.writeHead(404);
    res.end("Not Found\n");
    return;
  }

  let body = "";
  req.on("data", (chunk) => { body += chunk; });
  req.on("end", async () => {
    const signature = req.headers["x-hub-signature-256"];
    if (!verifySignature(body, signature)) {
      console.error("Invalid webhook signature");
      res.writeHead(401);
      res.end("Invalid signature\n");
      return;
    }

    let payload;
    try {
      payload = JSON.parse(body);
    } catch {
      res.writeHead(400);
      res.end("Invalid JSON\n");
      return;
    }

    const action = payload.action;
    const repoUrl = payload.repository && payload.repository.html_url;
    const labels = payload.workflow_job && payload.workflow_job.labels;

    if (action !== "queued") {
      console.log(`Ignoring workflow_job action: $${action}`);
      res.writeHead(200);
      res.end("Ignored\n");
      return;
    }

    if (!labels || !labels.includes("self-hosted")) {
      console.log(`Ignoring job with labels: $${JSON.stringify(labels)}`);
      res.writeHead(200);
      res.end("Ignored\n");
      return;
    }

    if (!repoUrl) {
      res.writeHead(400);
      res.end("Missing repository URL\n");
      return;
    }

    try {
      const result = await dispatchRunner(repoUrl);
      console.log(`Dispatched runner for $${repoUrl}: $${result.DispatchedJobID}`);
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ dispatched: result.DispatchedJobID }) + "\n");
    } catch (err) {
      console.error(`Dispatch failed: $${err.message}`);
      res.writeHead(502);
      res.end(`Dispatch failed: $${err.message}\n`);
    }
  });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Webhook server listening on port $${PORT}`);
});
JSEOF
        destination = "local/dispatcher.js"
      }

      resources {
        cpu        = 100
        memory     = 256
        memory_max = 512
      }
    }
  }
}
