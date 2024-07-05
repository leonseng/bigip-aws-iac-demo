variable "bigip_address" {
  type = string
}

variable "bigip_instance_id" {
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

variable "bigip_external_route_network" {
  type = string
}

variable "bigip_external_route_gw" {
  type = string
}

variable "bigip_internal_self_ip" {
  type = string
}

variable "bigip_internal_route_network" {
  type = string
}

variable "bigip_internal_route_gw" {
  type = string
}

variable "workload_ips" {
  type = list(string)
}
