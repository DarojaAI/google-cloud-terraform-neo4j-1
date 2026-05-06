##########################################
####### Instance Outputs
##########################################

output "instance_name" {
  description = "Neo4j VM instance name"
  value       = google_compute_instance.neo4j.name
}

output "internal_ip" {
  description = "Neo4j internal IP address (VPC)"
  value       = google_compute_instance.neo4j.network_interface[0].network_ip
}

output "external_ip" {
  description = "Neo4j external IP address (null if assign_external_ip = false)"
  value       = local.use_custom_vpc ? (var.assign_external_ip ? google_compute_instance.neo4j.network_interface[0].access_config[0].nat_ip : null) : google_compute_instance.neo4j.network_interface[0].access_config[0].nat_ip
}

output "neo4j_browser_url" {
  description = "Neo4j Browser URL"
  value       = "http://${coalesce(google_compute_instance.neo4j.network_interface[0].network_ip, google_compute_instance.neo4j.network_interface[0].access_config[0].nat_ip)}:7474"
}

output "neo4j_bolt_endpoint" {
  description = "Neo4j Bolt Endpoint"
  value       = "bolt://${coalesce(google_compute_instance.neo4j.network_interface[0].network_ip, google_compute_instance.neo4j.network_interface[0].access_config[0].nat_ip)}:7687"
}

output "connection_info" {
  description = "Neo4j connection information object"
  value = {
    host         = coalesce(google_compute_instance.neo4j.network_interface[0].network_ip, google_compute_instance.neo4j.network_interface[0].access_config[0].nat_ip)
    bolt_port    = 7687
    browser_port = 7474
    browser_url  = "http://${coalesce(google_compute_instance.neo4j.network_interface[0].network_ip, google_compute_instance.neo4j.network_interface[0].access_config[0].nat_ip)}:7474"
    bolt_uri     = "bolt://${coalesce(google_compute_instance.neo4j.network_interface[0].network_ip, google_compute_instance.neo4j.network_interface[0].access_config[0].nat_ip)}:7687"
    internal     = local.use_custom_vpc
    requires_vpn = local.use_custom_vpc
  }
}