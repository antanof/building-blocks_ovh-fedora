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
