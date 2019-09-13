variable "traefik_network_id" {
  type        = string
  description = "This is the Docker network ID that Visualizer needs to connect to so Traefik can proxy its requests."
}

variable "visualizer_dns" {
  type        = string
  description = "This is the domain name that should be used by the Visualizer Docker service."
}

variable "web_users" {
  type = list
  description = "A list of strings containing username and one-way hashed passwords that will be allowed to log into the Traefik user interface."
}
