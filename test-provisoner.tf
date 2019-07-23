# Null resourse that Copies the apache config, index.html to server and restarts apache
  resource "null_resource" "provision_webserver5" {
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

  depends_on = ["aws_instance.stadevtest2", "aws_security_group.testappserver1-sg"]

}

