output "neo4j_http_url" {
  description = "URL to access Neo4j Browser via load balancer"
  value       = "http://someip:7474"
}

output "neo4j_bolt_endpoint" {
  description = "Bolt endpoint for Neo4j connections via load balancer"
  value       = "bolt://someip:7687"
}
