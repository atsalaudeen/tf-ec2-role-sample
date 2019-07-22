provider "aws" {
  version = "~> 2.17"
  region = "us-east-1"
}


resource "aws_instance" "stadevtest2" {
  ami = "ami-0b898040803850657"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.testappserver1-sg.id}"]

  # use this to attach existing role
  #iam_instance_profile = "tfadmin"

  # use if creating new key below
  #key_name = "deployer-key"

  # use for existing key
  key_name = "test-acc-only"

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
    sudo yum install -y httpd php gd php-gd php-xml php-json php-mbstring php-process php-common php-zip php-mysqlnd php-opcache
    #php -v
    sudo yum install -y nfs-utils
    sudo yum install -y cachefilesd
    sudo yum install -y java-1.8.0-openjdk.x86_64
    sudo yum install -y php-soap.x86_64
    sudo service cachefilesd start
    sudo chkconfig cachefilesd on
    sudo mkdir -p /var/www/html/web/www

    # This is just a demo. We use provisioner later 
    sudo cat > /var/www/html/web/www/index.test <<'_END'
          <html lang="en" dir="ltr">
            <head>
              <meta charset="utf-8">
              <title>Welcome to Test Demo Page</title>
              <style media="screen">
                body {
                  background-color: #3FBFBF;
                }
              </style>
            </head>
            <body> 
            <h1>Welcome to test env 1</h1>
            <p>Testing webservers</p>
            <p>This is traffic from node 1</p>
          
            </body>
          </html>
        -END

  EOF

  # Local provisioner to get ip address
  provisioner "local-exec" {
    command = "echo ${aws_instance.stadevtest2.private_ip} >> appserver_private_ips.txt"
  }

}

# Null resourse that Copies the apache config, index.html to server and restarts apache
  resource "null_resource" "provision_webserver1" {
    connection {
        type        = "ssh"
        user        = "ec2-user"
        #private_key = "${var.private_key}"
        private_key = "${file("/home/ec2-user/.ssh/test.pem")}"
        host = "${aws_instance.stadevtest2.public_ip}"
    }

    # Provisioner to copy apache conf file 
    
    provisioner "file" {
         source      = "conf/apache-overrides.conf"
         destination = "/tmp/apache-overrides.conf"
    }
    
    # add remote exec provisioner to be able to copy file with correct permision 
    provisioner "remote-exec" {
      inline = [
        "sudo chown root:root /tmp/apache-overrides.conf",
        "sudo mv /tmp/apache-overrides.conf /etc/httpd/conf.d/apache-overrides.conf",
      ]
    }

    # provisioner to copy index.html and restart apache 

  provisioner "file" {
       source      = "conf/index.html"
       destination = "/tmp/index.html"
  }
  
  # add remote exec provisioner to be able to copy file with correct permision 
  provisioner "remote-exec" {
    inline = [
      "sudo chown root:root /tmp/index.html",
      "sudo mv /tmp/index.html /var/www/html/web/www/index.html",
      "sudo systemctl restart httpd",
    ]
  }

  depends_on = ["aws_security_group.testappserver1-sg"]

}

# Create keypair to add ssh key to the instance
# skip if already created on aws
#resource "aws_key_pair" "deployerkey" {
#  key_name = "deployer-key"
#  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQASRzcJWCyHRAfq61Po0POfu33rxJiEYviGKrpWxNfrogzrlCCesilXi3wNw641jczagDLFKmb72EYtUxnhm878IhO6Vurifq/oep7+jkLvl8jjhgg90f2r44gabaKHKrU9jkuk0ib1mD test-only"
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

