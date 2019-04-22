provider "aws" {
  version = "~> 2.7"
  region  = "${var.aws-region}"
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

module "allow-http-https" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "allow-http-https"
  description = "Allow traffic on ports 80 and 443 for all IP addresses."
  vpc_id      = "${aws_default_vpc.default.id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
}

module "allow-ssh-restricted" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "allow-ssh-restricted"
  description = "Allow ssh connections to a restricted range of IP addresses."
  vpc_id      = "${aws_default_vpc.default.id}"

  ingress_cidr_blocks = ["${var.ssh-ip-range}"]
  ingress_rules       = ["ssh-tcp"]
}

resource "aws_instance" "my_instance" {
  ami           = "ami-0a313d6098716f372"
  instance_type = "t2.micro"

  security_groups = ["default"]

  vpc_security_group_ids = [
    "${module.allow-http-https.this_security_group_id}",
    "${module.allow-ssh-restricted.this_security_group_id}",
  ]

  key_name = "${var.key-name}"
}

resource "null_resource" "instance-provisioning" {
  triggers = {
    public_ip = "${aws_instance.my_instance.public_ip}"
  }

  connection {
    type        = "ssh"
    host        = "${aws_instance.my_instance.public_ip}"
    user        = "ubuntu"
    port        = 22
    private_key = "${file("${var.private-key-path}")}"
  }

  provisioner "file" {
    source      = "scripts/install-docker-ce.bash"
    destination = "/tmp/install-docker-ce.bash"
    on_failure  = "fail"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-docker-ce.bash",
      "sudo /tmp/install-docker-ce.bash ${var.docker-ce-version} > /dev/null",
    ]

    on_failure = "fail"
  }

  provisioner "remote-exec" {
    inline     = "sudo docker run -d --name https --network=host --restart=always httpd"
    on_failure = "fail"
  }
}
