
output "my-instance-ip" {
  value = "${aws_instance.my_instance.public_ip}"
}