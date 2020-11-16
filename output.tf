output "Server_IP" {
  value = openstack_networking_port_v2.public_a.all_fixed_ips
}
