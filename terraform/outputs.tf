
output "web_server_public_ip" {
  description = "Public IP address of the TravelMemory web server"
  value       = aws_instance.web.public_ip
}

output "database_private_ip" {
  description = "Private IP address of the MongoDB database server"
  value       = aws_instance.database.private_ip
}
