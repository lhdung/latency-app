output "latency_monitor_public_ip" {
  description = "Public IP address of the latency monitor server"
  value       = aws_eip.latency_monitor.public_ip
}

output "target_server_public_ip" {
  description = "Public IP address of the target server"
  value       = aws_eip.target_server.public_ip
}

output "latency_monitor_endpoint" {
  description = "URL to access the latency monitoring application"
  value       = "http://${aws_eip.latency_monitor.public_ip}:8000"
}

output "latency_api_endpoint" {
  description = "URL to access the latency API"
  value       = "http://${aws_eip.latency_monitor.public_ip}:8000/latency"
}

output "metrics_endpoint" {
  description = "URL to access the Prometheus metrics"
  value       = "http://${aws_eip.latency_monitor.public_ip}:8000/metrics"
}

output "target_server_http_endpoint" {
  description = "URL to access the target server (HTTP)"
  value       = "http://${aws_eip.target_server.public_ip}"
}

output "target_server_https_endpoint" {
  description = "URL to access the target server (HTTPS)"
  value       = "https://${aws_eip.target_server.public_ip}"
}

output "ssh_commands" {
  description = "SSH commands to connect to the servers"
  value = {
    latency_monitor = "ssh -i ~/.ssh/latency-monitor ubuntu@${aws_eip.latency_monitor.public_ip}"
    target_server   = "ssh -i ~/.ssh/latency-monitor ubuntu@${aws_eip.target_server.public_ip}"
  }
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "deployment_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    region                    = var.aws_region
    environment              = var.environment
    latency_monitor_ip       = aws_eip.latency_monitor.public_ip
    target_server_ip         = aws_eip.target_server.public_ip
    monitoring_app_url       = "http://${aws_eip.latency_monitor.public_ip}:8000/latency"
    target_being_monitored   = "${aws_eip.target_server.public_ip}:80"
    docker_image_used        = var.docker_image
    vpc_cidr                 = aws_vpc.main.cidr_block
  }
}

output "verification_commands" {
  description = "Commands to verify the deployment"
  value = {
    check_latency_monitor = "curl http://${aws_eip.latency_monitor.public_ip}:8000/latency"
    check_target_server   = "curl http://${aws_eip.target_server.public_ip}/status"
    check_metrics         = "curl http://${aws_eip.latency_monitor.public_ip}:8000/metrics"
    check_health          = "curl http://${aws_eip.latency_monitor.public_ip}:8000/health"
  }
}
