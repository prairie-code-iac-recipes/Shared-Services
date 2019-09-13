provider "aws" {
  version       = "~> 2.23"
  region        = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "com.iac-example"
    key            = "shared-containers"
    region         = "us-east-1"
    dynamodb_table = "terraform-statelock"
  }
}

provider "docker" {
  version = "~> 2.2"

# Hard-coded is not acceptable. Although the docker provisioner doesn't allow variables here.
# May need to consider a single cluster with labels indicating the environment you are deploying to.
  host          = "tcp://docker-dev-manager.iac-example.com:2376/"

  ca_material   = "${base64decode(var.DOCKER_CA_CRT)}"
  cert_material = "${base64decode(var.DOCKER_CLIENT_CRT)}"
  key_material  = "${base64decode(var.DOCKER_CLIENT_KEY)}"
}

provider "null" {
  version = "~> 2.1"
}

locals {
  aws_region          = "us-east-1"
  docker_group_tag    = "Docker Infrastructure"
  domain              = "iac-example.com"
  efs_mount_target    = "/mnt/efs"
  swarm_manager_dns   = "docker-${terraform.workspace}-manager.iac-example.com"
  traefik_hostname    = "traefik-${terraform.workspace}"
  traefik_dns         = "${local.traefik_hostname}.${local.domain}"
  visualizer_hostname = "viz-${terraform.workspace}"
  visualizer_dns      = "${local.visualizer_hostname}.${local.domain}"
  web_users           = [
    "dave:$apr1$6EvOVJPK$x7lrTD9wOV5f7Al.V3KAc/"
  ]
}

###############################################################################
# Fetch AWS-Assigned Information for Use Downstream
###############################################################################
data "aws_instances" "docker_hosts" {
  instance_tags = {
    Group = "${local.docker_group_tag}"
  }

  instance_state_names = ["running"]
}

data "aws_route53_zone" "primary" {
  name = "${local.domain}."
}

###############################################################################
# Create DNS Entries for Traefik and Visualizer
###############################################################################
resource "aws_route53_health_check" "default" {
  count = "${length(data.aws_instances.docker_hosts.public_ips)}"

  ip_address        = "${data.aws_instances.docker_hosts.public_ips[count.index]}"
  port              = 22
  type              = "TCP"
  failure_threshold = "5"
  request_interval  = "30"
}

resource "aws_route53_record" "traefik" {
  count           = "${length(data.aws_instances.docker_hosts.public_ips)}"

  zone_id         = "${data.aws_route53_zone.primary.id}"
  name            = "${local.traefik_dns}"
  type            = "A"
  ttl             = "30"
  health_check_id = "${aws_route53_health_check.default[count.index].id}"

  weighted_routing_policy {
    weight = 10
  }
  set_identifier  = "${format("${local.traefik_hostname}.${local.domain}.%02d", count.index+1)}"

  records = [
    "${data.aws_instances.docker_hosts.public_ips[count.index]}"
  ]
}

resource "aws_route53_record" "viz" {
  count           = "${length(data.aws_instances.docker_hosts.public_ips)}"

  zone_id         = "${data.aws_route53_zone.primary.id}"
  name            = "${local.visualizer_dns}"
  type            = "A"
  ttl             = "30"
  health_check_id = "${aws_route53_health_check.default[count.index].id}"

  weighted_routing_policy {
    weight = 10
  }
  set_identifier  = "${format("${local.visualizer_hostname}.${local.domain}.%02d", count.index+1)}"

  records = [
    "${data.aws_instances.docker_hosts.public_ips[count.index]}"
  ]
}

###############################################################################
# Launch Traefik to Handle Dynamic Service Discovery and Load Balancing
###############################################################################
module "traefik" {
  source = "./modules/traefik"

  aws_region            = "${var.SSH_USERNAME}"
  aws_access_key_id     = "${var.AWS_ACCESS_KEY_ID}"
  aws_secret_access_key = "${var.AWS_SECRET_ACCESS_KEY}"
  efs_mount_target      = "${local.efs_mount_target}"
  ssh_private_key       = "${base64decode(var.SSH_PRIVATE_KEY)}"
  swarm_manager_dns     = "${local.swarm_manager_dns}"
  traefik_dns           = "${local.swarm_manager_dns}"
  user                  = "${var.SSH_USERNAME}"
  web_users             = "${local.web_users}"
}

###############################################################################
# Launch Visualizer to Provide a Nice View of Running Containers
###############################################################################
module "visualizer" {
  source = "./modules/visualizer"

  traefik_network_id = "${module.traefik.traefik_network_id}"
  visualizer_dns     = "${local.visualizer_dns}"
  web_users          = "${local.web_users}"
}
