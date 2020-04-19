resource "aws_instance" "ec2_server" {
  ami                    = "ami-0435a5d3380f2aa58"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ssh_key.key_name

  vpc_security_group_ids = [
    aws_security_group.http_sg.id,
    aws_security_group.ssh_sg.id,
    aws_security_group.egress_sg.id
  ]

  tags = {
    Name = "ubuntu-tor"
  }

  provisioner "file" {
    source      = "../torrc"
    destination = "/tmp/torrc"
  }

  provisioner "file" {
    source      = "../hidden_service.conf"
    destination = "/tmp/hidden_service.conf"
  }

  provisioner "file" {
    source      = "../clearnet_service.conf"
    destination = "/tmp/clearnet_service.conf"
  }

  provisioner "file" {
    source      = "../config-machine.sh"
    destination = "/tmp/config-machine.sh"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key)
    host        = aws_instance.ec2_server.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/config-machine.sh",
      "/tmp/config-machine.sh"
    ]
  }
}