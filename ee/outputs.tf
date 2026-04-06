output "neo4j_http_url" {
  description = "URL to access Neo4j Browser via load balancer"
  value       = "The Neo4j Browser UI will be available on any node at http://externalIP:7474"
}

output "neo4j_bolt_endpoint" {
  description = "Bolt endpoint for Neo4j connections via load balancer"
  value       = "The Neo4j BOLT endpoint will be available on any node at http://externalIP:7474"
}
