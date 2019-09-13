output "traefik_network_id" {
  description = "Identifies the network that containers should connect to so that Traefik can serve as a proxy for them."
  value       = "${docker_network.dmz.id}"
}
