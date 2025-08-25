# Simple Development Environment Outputs

output "latency_monitor_ip" {
  description = "Public IP of the latency monitor server"
  value       = module.simple_deployment.latency_monitor_public_ip
}

output "target_server_ip" {
  description = "Public IP of the target server"
  value       = module.simple_deployment.target_server_public_ip
}

output "latency_monitor_url" {
  description = "URL to access the latency monitoring application"
  value       = module.simple_deployment.latency_monitor_endpoint
}

output "target_server_url" {
  description = "URL to access the target server"
  value       = module.simple_deployment.target_server_http_endpoint
}

output "ssh_commands" {
  description = "SSH commands to connect to the servers"
  value       = module.simple_deployment.ssh_commands
}

output "quick_test_commands" {
  description = "Commands to quickly test the deployment"
  value = {
    test_api    = "curl ${module.simple_deployment.latency_api_endpoint}"
    test_target = "curl ${module.simple_deployment.target_server_http_endpoint}/status"
    test_health = "curl ${module.simple_deployment.latency_monitor_endpoint}/health"
  }
}