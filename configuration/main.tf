provider "bigip" {
  address  = var.bigip_hostname
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
      hostname         = var.bigip_hostname
      admin_user       = var.bigip_username
      admin_password   = var.bigip_password
      external_self_ip = var.bigip_external_self_ip
      internal_self_ip = var.bigip_internal_self_ip
    }
  )
}

resource "local_file" "do_json" {
  content  = local.do_json
  filename = "${path.module}/.bigip/do.json"
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
  filename = "${path.module}/.bigip/as3.json"
}


resource "bigip_as3" "this" {
  depends_on = [
    bigip_do.this
  ]

  as3_json = local.as3_json
}
