resource "aws_key_pair" "ssh_key" {
  key_name   = "tor_sauce"
  public_key = var.public_key
}