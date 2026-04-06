output "neo4j_browser_url" {
  description = "Neo4j Browser URL"
  value       = "http://${google_compute_instance.neo4j.network_interface.0.access_config.0.nat_ip}:7474"
}

output "neo4j_bolt_endpoint" {
  description = "Neo4j Bolt Endpoint"
  value       = "bolt://${google_compute_instance.neo4j.network_interface.0.access_config.0.nat_ip}:7687"
}
