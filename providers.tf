terraform {
 backend "swift" {
   region = var.region
 }
 required_providers {
  openstack = {
     source = "terraform-provider-openstack/openstack"
   }

   ovh = {
     source = "ovh/ovh"
   }
 }
}

 provider "openstack" {
  region   = var.region
  alias    = "ovh"
}

provider "ovh" {
  endpoint = "ovh-eu"
  alias    = "ovh"
}

# # Configure le fournisseur OpenStack hébergé par OVH
# provider "openstack" {
#  auth_url = "https://auth.cloud.ovh.net/v3.0/" # URL d'authentification
#  domain_name = "default" # Nom de domaine - Toujours à "default" pour OVH
#  tenant_name = ""
#  alias = "ovh"
#  user_name   = var.openstack_user
#  password    = var.openstack_password
# }
#
# provider "ovh" {
#  endpoint = "ovh-eu" # Point d'entrée du fournisseur
#  alias = "ovh" # Un alias
# }
