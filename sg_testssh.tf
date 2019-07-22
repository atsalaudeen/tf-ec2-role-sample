resource "aws_security_group" "testappserver1-sg" {
  name = "testappserver-sg" 
  description = "security group for ssh and http access to testenv"


  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["81.145.139.130/32"]
    description = "Test Mgmt Network"
  }

# narrow down to specific security group
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #security_groups = ["sg-0fca1a86b3f4ebd6f"]
    #security_groups = ["${aws_security_group.tf-mgmtserver-sg.id}"]
  }

#
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-testappserver1"
  }
}
