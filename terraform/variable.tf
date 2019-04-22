variable "aws-region" {
  description = "AWS region to create instance."
  type = "string"
}

variable "ssh-ip-range" {
  description = "IP or range to authorize ssh connections."
  type = "list"
}

variable "key-name" {
  description = "Key pair name present on given aws-region to associate with instance."
  type = "string"
}

variable "private-key-path" {
  description = "Path to private key file. Needed to execute remote commands during provisioning."
  default     = "~/.ssh/id_rsa"
  type = "string"
}

variable "docker-ce-version" {
  description = "Docker CE version to be installed on provisioned instance. If not specified, latest version will be installed."
  default     = ""
  type = "string"
}