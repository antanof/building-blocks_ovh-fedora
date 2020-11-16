resource "openstack_compute_keypair_v2" "mattkey" {
  provider   = openstack.ovh
  name       = "${var.linux_user}-key"
  public_key = file(var.ssh_key_file)
}


data "openstack_networking_network_v2" "public_a" {
  name     = "Ext-Net"
  provider = openstack.ovh
}

resource "openstack_networking_port_v2" "public_a" {
  name           = "port_${var.instance_name}"
  network_id     = data.openstack_networking_network_v2.public_a.id
  admin_state_up = "true"
  provider       = openstack.ovh
}

data "http" "myip" {
  url = "https://api.ipify.org"
}

data "template_file" "setup" {
  template = <<SETUP
#!/bin/bash
# install & configure firewall, cockpit
dnf install -y firewalld cockpit
systemctl enable --now firewalld.service
systemctl start firewalld.service
systemctl enable --now cockpit.socket
systemctl start cockpit.socket
firewall-cmd --permanent --add-source=${trimspace(data.http.myip.body)}/32 --zone=trusted
firewall-cmd --permanent --add-service=ssh --zone trusted
firewall-cmd --permanent --add-service=cockpit --zone trusted
firewall-cmd --permanent --remove-service=ssh --zone public
firewall-cmd --reload
SETUP
}

data "template_file" "userdata" {
  template = <<CLOUDCONFIG
#cloud-config
hostname: ${var.instance_name}
fqdn: ${var.instance_name}
ssh_pwauth: true
manage_etc_hosts: true
chpasswd:
  list: |
     root: StrongPassword
  expire: False
users:
  - name: ${var.linux_user}
    passwd: ${var.linux_user_passwd}
    lock-passwd: false
    ssh_authorized_keys:
      - ${var.ssh_key_fingerprint}
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
    groups: wheel
write_files:
  - path: /tmp/setup/run.sh
    permissions: '0755'
    content: |
      ${indent(6, data.template_file.setup.rendered)}
  - path: /etc/systemd/network/30-ens3.network
    permissions: '0644'
    content: |
      [Match]
      Name=ens3
      [Network]
      DHCP=ipv4
runcmd:
  - hostnamectl set-hostname ${var.instance_name}
  - sh /tmp/setup/run.sh
disk_setup:
  /dev/sdb:
    table_type: gpt
    layout: True
    overwrite: False
fs_setup:
  - label: DATA_XFS
    filesystem: xfs
    device: '/dev/sdb'
    partition: auto
mounts:
  - [ LABEL=DATA_XFS, /mnt/data, xfs ]
output:
   init:
       output: "> /var/log/cloud-init.out"
       error: "> /var/log/cloud-init.err"
   config: "tee -a /var/log/cloud-config.log"
   final:
       - ">> /var/log/cloud-final.out"
       - "/var/log/cloud-final.err"
final_message: "The system is finall up, after $UPTIME seconds"
CLOUDCONFIG
}

data "openstack_images_image_v2" "fedora" {
  region      = var.region
  name        = "Fedora 32" # Nom de l'image
  most_recent = true # Limite la recherche à la plus récente
  provider    = openstack.ovh # Nom du fournisseur
}

resource "openstack_blockstorage_volume_v2" "backup" {
  region      = var.region
  name        = "data_disk" # Nom du périphérique de stockage
  size        = 10 # Taille
  provider    = openstack.ovh # Nom du fournisseur
}

resource "openstack_compute_instance_v2" "fed_test" {
  region          = var.region
  name 	          = var.instance_name
  provider        = openstack.ovh
  image_name      = "Fedora 32"
  flavor_name     = "b2-15"
  user_data       = data.template_file.userdata.rendered
  key_pair        = openstack_compute_keypair_v2.mattkey.name
  security_groups = [openstack_networking_secgroup_v2.secgroup_1.name] # Ajoute la machine au groupe de sécurité
   # network {
   #   name    = "Ext-Net"
   # }
  network {
      access_network = true
      port           = openstack_networking_port_v2.public_a.id
  }
  network {
      name = var.private_network
   # Adresse IP prise depuis la liste défini précédemment
   # fixed_ip_v4 = "${element(var.front_private_ip, count.index)}"
  }

  block_device {
    uuid                  = data.openstack_images_image_v2.fedora.id # Identifiant de l'image de la machine
    source_type           = "image" # Type de source
    destination_type      = "local" # Destination
    volume_size           = 100 # Taille
    boot_index            = 0 # Ordre de boot
    delete_on_termination = true # Le périphérique sera supprimé avec la machine
  }
  block_device {
    uuid                  = openstack_blockstorage_volume_v2.backup.id # Identifiant du périphérique de stockage
    source_type           = "volume" # Type de source
    destination_type      = "volume" # Destination
    boot_index            = 1 # Ordre de boot
    delete_on_termination = true # Le périphérique sera supprimé avec la machine
  }
}

output "Server_IP" {
  value = openstack_networking_port_v2.public_a.all_fixed_ips
}
