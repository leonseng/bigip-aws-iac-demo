variable "bigip_hostname" {
  type = string
}

variable "bigip_username" {
  type = string
}

variable "bigip_password" {
  type = string
}

variable "bigip_external_self_ip" {
  type = string
}

variable "bigip_internal_self_ip" {
  type = string
}

variable "workload_ips" {
  type = list(string)
}
