resource "docker_service" "visualizer_service" {
  name     = "visualizer"

  labels = {
    "traefik.docker.network" = "dmz"
    "traefik.enable" = "true"
    "traefik.frontend.rule" = "Host:${var.visualizer_dns}"
    "traefik.port" = 8080
    "traefik.protocol" = "http"
    "traefik.frontend.entryPoints" = "https"
    "traefik.frontend.auth.basic.users" = "${join(",", var.web_users)}"
  }

  task_spec {
    container_spec {
      image = "dockersamples/visualizer:latest"

      mounts {
        target      = "/var/run/docker.sock"
        source      = "/var/run/docker.sock"
        type        = "bind"
        read_only   = false
      }
    }

    networks = ["${var.traefik_network_id}"]

    restart_policy = {
      condition    = "any"
      delay        = "3s"
      max_attempts = 4
      window       = "10s"
    }

    placement {
      constraints = [
        "node.role==manager",
      ]
      prefs = [
        "spread=node.role.manager",
      ]
    }
  }
}
