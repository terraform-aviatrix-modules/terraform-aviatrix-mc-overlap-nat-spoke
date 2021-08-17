variable "spoke_gw_object" {
  description = "Aviatrix Spoke Gateway object with all of it's attributes."
}

variable "spoke_cidrs" {
  description = "VNET or VPC CIDRs (typically one, but can be multiple)"
}

variable "transit_gw_name" {
  description = "Name of the transit gateway, to determine the connection for SNAT rule."
}

variable "gw1_snat_addr" {
  description = "IP Address to be used for hide natting traffic sourced from the spoke VNET/VPC"
}

variable "gw2_snat_addr" {
  description = "IP Address to be used for hide natting traffic sourced from the spoke VNET/VPC. Required when spoke is HA pair."
  default     = ""
}

variable "dnat_addrs" {
  description = "When DNAT rules are configured, the addresses used for them, need to be configured in this list."
  default     = []
}

variable "dnat_rules" {
  description = "Contains the properties to create the DNAT rules. When left empty, only SNAT for traffic initiated from the spoke VNET/VPC is configured."
  type        = map(any)
  default     = {}
}

locals {
  is_ha = length(var.spoke_gw_object.ha_gw_name) > 0 ? true : false
}
