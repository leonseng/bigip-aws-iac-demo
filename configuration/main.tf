provider "bigip" {
  address  = var.bigip_address
  username = var.bigip_username
  password = var.bigip_password
}

#
# DO
#
locals {
  do_json = templatefile(
    "${path.module}/templates/do.json.tpl",
    {
      hostname               = "${var.bigip_instance_id}.local"
      admin_user             = var.bigip_username
      admin_password         = var.bigip_password
      external_self_ip       = var.bigip_external_self_ip
      external_route_network = var.bigip_external_route_network
      external_route_gw      = var.bigip_external_route_gw
      internal_self_ip       = var.bigip_internal_self_ip
      internal_route_network = var.bigip_internal_route_network
      internal_route_gw      = var.bigip_internal_route_gw

    }
  )
}

resource "local_file" "do_json" {
  content  = local.do_json
  filename = "${path.module}/.bigip/${var.bigip_instance_id}/do.json"
}


resource "bigip_do" "this" {
  do_json = local.do_json
}

#
# AS3
#
locals {
  as3_json = templatefile(
    "${path.module}/templates/as3.json.tpl",
    {
      vs_vip           = "${split("/", var.bigip_external_self_ip)[0]}"
      server_addresses = join(",", [for ip in var.workload_ips : "\"${ip}\""])
    }
  )
}

resource "local_file" "as3_json" {
  content  = local.as3_json
  filename = "${path.module}/.bigip/${var.bigip_instance_id}/as3.json"
}


resource "bigip_as3" "this" {
  depends_on = [
    bigip_do.this
  ]

  as3_json = local.as3_json
}
