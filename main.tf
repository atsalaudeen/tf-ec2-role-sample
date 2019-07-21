provider "aws" {
  version = "~> 2.17"
  region = "us-east-1"
}


resource "aws_instance" "stadevtest2" {
  ami = "ami-0b898040803850657"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.testssh2.id}"]

  # use this to attach existing role
  #iam_instance_profile = "tfadmin"
  
  # use if creating new key below
  #key_name = "deployer-key"
  
  # use for existing key
  key_name = "sta-acc-only"
  
  # attach new profile to be created 
  iam_instance_profile = "test_profile"
  tags = {
    Name = "Dev-Test4"
  }

  # ensure that role is created first
  #depends_on = [aws_iam_role.sta_admin_role]
  depends_on = [aws_iam_instance_profile.test_profile]


 #user_data = "./install.sh"
  # can add the following to install.sh script instead.

 user_data = <<EOF
    #! /bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install -y php7.3
    sudo yum install -y httpd nginx
    php -v
    sudo yum install -y php-soap.x86_64
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo systemctl start nginx
    sudo systemctl enable nginx 
    sudo mkdir -p /var/www/html/web/www
    sudo wget https://releases.hashicorp.com/terraform/0.12.3/terraform_0.12.3_linux_amd64.zip
    sudo unzip terraform_0.12.3_linux_amd64.zip
    sudo cat > /var/www/html/web/www/index.html <<'_END'
          <h1>Welcome to testing env</h1>
          <p>
          This is first ec2 app server. 
        -END
  EOF

  # Local provisioner to get ip address
  provisioner "local-exec" {
    command = "echo ${aws_instance.stadevtest2.private_ip} >> appserver_private_ips.txt"
  }

  # Copies the myapp.conf file to /tmp/myapp.conf
  provisioner "file" {
    source      = "conf/myapp.conf"
    destination = "/tmp/myapp.conf"
  }

  provisioner "local-exec" {
    command = "echo `php -v` >> appserver_private_ips.txt"
  }

}

# Create keypair to add ssh key to the instance 
# skip if already created on aws
#resource "aws_key_pair" "deployerkey" {
#  key_name = "deployer-key"
#  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdPj/e8HJkSRzcJWCyHRAfq61Po0POfu33rxJiEYviGKrpWxN7G9uadfrogzrlCCesilXi3wNw641jczagDLFKmb72EYtUxnhmi8ba9ouOUnIhO6Vurifq/oep7+jkLvl8jjhgg90f2r44gabaKHKrU9jkuk0ib1mD test-only"
#}

# create and attach a profile to this instance

# create profile 

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = "${aws_iam_role.sta_admin_role.name}"
}


# create role 
resource "aws_iam_role" "sta_admin_role" {
  name = "TF_Admin_Role"
  description = "Statech admin role for tform"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


# create the policy 


resource "aws_iam_policy" "tf_policy" {
  name        = "tf_test-policy"
  description = "Statech admin policy for tform"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# attach read only policy 
resource "aws_iam_role_policy_attachment" "ec2-read-only-policy-attachment" {
    role = "${aws_iam_role.sta_admin_role.name}"
    policy_arn = "${aws_iam_policy.tf_policy.arn}"
}

# output public ip

output "nodeipaddress" {
  value = "${aws_instance.stadevtest2.public_ip}"
}
