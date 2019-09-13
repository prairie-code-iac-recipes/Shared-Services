###############################################################################
# Set-up Data Directory on EFS Volume
###############################################################################
resource "null_resource" "traefik_config" {
  connection {
    user        = "${var.user}"
    private_key = "${var.ssh_private_key}"
    host        = "${var.swarm_manager_dns}"
    type        = "ssh"
  }

  triggers = {
    traefik_toml   = "${md5(file("${path.module}/traefik.toml"))}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eou pipefail",
      "if [ ! -d ${var.efs_mount_target}/traefik ]; then mkdir ${var.efs_mount_target}/traefik; fi",
      "if [ ! -f ${var.efs_mount_target}/traefik/acme.json ]; then",
      "  touch ${var.efs_mount_target}/traefik/acme.json",
      "  chmod 600 ${var.efs_mount_target}/traefik/acme.json",
      "fi"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/traefik.toml"
    destination = "${var.efs_mount_target}/traefik/traefik.toml"
  }
}

###############################################################################
# Create Network Designated for Internet-Facing Containers
###############################################################################
resource "docker_network" "dmz" {
  name   = "dmz"
  driver = "overlay"
}

###############################################################################
# Deploy Traefik Service
###############################################################################
resource "docker_service" "traefik" {
  name     = "traefik"

  labels = {
    "traefik.docker.network" = "dmz"
    "traefik.enable" = "true"
    "traefik.frontend.rule" = "Host:${var.traefik_dns}"
    "traefik.port" = 8080
    "traefik.protocol" = "http"
    "traefik.frontend.entryPoints" = "https"
    "traefik.frontend.auth.basic.users" = "${join(",", var.web_users)}"
  }

  task_spec {
    container_spec {
      image = "traefik:1.7-alpine"

      env = {
        AWS_REGION                 = "${var.aws_region}"
        AWS_ACCESS_KEY_ID          = "${var.aws_access_key_id}"
        AWS_SECRET_ACCESS_KEY      = "${var.aws_secret_access_key}"
      }

      mounts {
        target      = "/var/run/docker.sock"
        source      = "/var/run/docker.sock"
        type        = "bind"
        read_only   = false
      }

      mounts {
        target      = "/etc/traefik"
        source      = "${var.efs_mount_target}/traefik"
        type        = "bind"
        read_only   = false
      }
    }

    networks = ["${docker_network.dmz.id}"]

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

  endpoint_spec {
    mode = "vip"

    ports {
      name           = "HTTP"
      protocol       = "tcp"
      target_port    = "80"
      published_port = "80"
      publish_mode   = "ingress"
    }

    ports {
      name           = "HTTPS"
      protocol       = "tcp"
      target_port    = "443"
      published_port = "443"
      publish_mode   = "ingress"
    }

    ports {
      target_port    = "8080"
    }
  }

  depends_on = [
    null_resource.traefik_config
  ]
}
