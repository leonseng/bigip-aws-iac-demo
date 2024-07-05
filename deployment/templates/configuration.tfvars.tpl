/*
terraform -chdir=configuration workspace new ${bigip_instance_id}
terraform -chdir=configuration workspace select ${bigip_instance_id}
terraform -chdir=configuration init -upgrade
terraform -chdir=configuration apply -auto-approve -var-file=${bigip_instance_id}.tfvars
terraform -chdir=configuration workspace select default
*/

bigip_address = "${bigip_address}"
bigip_instance_id = "${bigip_instance_id}"
bigip_username = "${bigip_username}"
bigip_password = "${bigip_password}"
bigip_external_self_ip = "${bigip_external_self_ip}"
bigip_external_route_network = "${bigip_external_route_network}"
bigip_external_route_gw = "${bigip_external_route_gw}"
bigip_internal_self_ip = "${bigip_internal_self_ip}"
bigip_internal_route_network = "${bigip_internal_route_network}"
bigip_internal_route_gw = "${bigip_internal_route_gw}"
workload_ips = ${workload_ips}
