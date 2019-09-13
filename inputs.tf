variable "AWS_ACCESS_KEY_ID" {
  type        = string
  description = "This is the AWS access key used by Traefik to create text records in Route 53 while negotiating with Lets Encrypt to obtain new TLS certificates."
}

variable "AWS_SECRET_ACCESS_KEY" {
  type        = string
  description = "This is the AWS secret key used by Traefik to create text records in Route 53 while negotiating with Lets Encrypt to obtain new TLS certificates."
}

variable "DOCKER_CA_CRT" {
  type        = string
  description = "This is the public certificate for the certificate authority that generated the public/private keys used to secure the Docker socket from both a client and server perspective."
}

variable "DOCKER_CLIENT_CRT" {
  type        = string
  description = "This is the public key used by the client to connect to the secured Docker socket."
}

variable "DOCKER_CLIENT_KEY" {
  type        = string
  description = "This is the public key used by the client to connect to the secured Docker socket."
}

variable "SSH_PRIVATE_KEY" {
  type        = string
  description = "The contents of a base64-encoded SSH key to use for the connection."
}

variable "SSH_USERNAME" {
  type        = string
  description = "The user that we should use for the connection."
}
