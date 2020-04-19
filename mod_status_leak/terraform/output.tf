output "public_ip" {
  value       = aws_instance.ec2_server.public_ip
  description = "The public IP of the web server"
}