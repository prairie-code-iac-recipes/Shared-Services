variable "aws_region" {
  type = string
  description = "The AWS region that Traefik will use to manipulate Route 53 in support of Let's Encrypt auto TLS certificate issuance."
}

variable "aws_access_key_id" {
  type = string
  description = "The AWS access key ID that Traefik will use to manipulate Route 53 in support of Let's Encrypt auto TLS certificate issuance."
}

variable "aws_secret_access_key" {
  type = string
  description = "The AWS secret acces key that Traefik will use to manipulate Route 53 in support of Let's Encrypt auto TLS certificate issuance."
}

variable "efs_mount_target" {
  type        = string
  description = "The path on each instance where EFS will be mounted (if applicable)"
}

variable "swarm_manager_dns" {
  type        = string
  description = "This is the domain name assigned to one or more Swarm manager nodes."
}

variable "traefik_dns" {
  type        = string
  description = "This is the domain name that should be used by the Traefik Docker service."
}

variable "ssh_private_key" {
  type        = string
  description = "This is the private key used to connect to provisioned instances."
}

variable "user" {
  type        = string
  description = "The username that will be used to connect to instances."
}

variable "web_users" {
  type = list
  description = "A list of strings containing username and one-way hashed passwords that will be allowed to log into the Traefik user interface."
}

