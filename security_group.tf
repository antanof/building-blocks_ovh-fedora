resource "openstack_networking_secgroup_v2" "secgroup_1" {
  region      = var.region
  name        = "secgroup_1"
  description = "My neutron security group"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1" {
  region            = var.region
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "${trimspace(data.http.myip.body)}/32"
  security_group_id = openstack_networking_secgroup_v2.secgroup_1.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_2" {
  region            = var.region
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9090
  port_range_max    = 9090
  remote_ip_prefix  = "${trimspace(data.http.myip.body)}/32"
  security_group_id = openstack_networking_secgroup_v2.secgroup_1.id
}
