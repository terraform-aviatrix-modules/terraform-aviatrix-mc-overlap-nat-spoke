resource "aviatrix_gateway_snat" "gw_1" {
  gw_name   = var.spoke_gw_object.gw_name
  snat_mode = "customized_snat"

  #SNAT Policy for all VPC CIDR's towards tunnel interface to transit
  dynamic "snat_policy" {
    for_each = { for cidr in var.spoke_cidrs : cidr => cidr }
    content {
      src_cidr   = snat_policy.value
      dst_cidr   = "0.0.0.0/0"
      connection = var.transit_gw_name
      protocol   = "all"
      snat_ips   = var.gw1_snat_addr
    }
  }

  #SNAT Policy for all traffic inbound to spoke, to pin return traffic to same spoke GW
  dynamic "snat_policy" {
    for_each = { for cidr in var.spoke_cidrs : cidr => cidr }
    content {
      src_cidr   = "0.0.0.0/0"
      dst_cidr   = snat_policy.value
      connection = "None"
      interface  = "eth0"
      protocol   = "all"
      snat_ips   = var.spoke_gw_object.private_ip
    }
  }

  #SNAT policy for Egress NAT (e.g. for distributed FQDN egress on spoke GW)
  dynamic "snat_policy" {
    for_each = var.egress_nat ? { for cidr in var.spoke_cidrs : cidr => cidr } : {} #Only create SNAT policy if egress NAT is turned on.
    content {
      src_cidr   = snat_policy.value
      connection = "None"
      interface  = "eth0"
      protocol   = "all"
      snat_ips   = var.spoke_gw_object.private_ip
    }
  }
}

resource "aviatrix_gateway_snat" "gw_2" {
  count     = local.is_ha ? 1 : 0
  gw_name   = local.is_ha ? var.spoke_gw_object.ha_gw_name : "dummy"
  snat_mode = "customized_snat"

  #SNAT Policy for all VPC CIDR's towards tunnel interface to transit
  dynamic "snat_policy" {
    for_each = { for cidr in var.spoke_cidrs : cidr => cidr }
    content {
      src_cidr   = snat_policy.value
      dst_cidr   = "0.0.0.0/0"
      connection = var.transit_gw_name
      protocol   = "all"
      snat_ips   = var.gw2_snat_addr
    }
  }

  #SNAT Policy for all traffic inbound to spoke, to pin return traffic to same spoke GW
  dynamic "snat_policy" {
    for_each = { for cidr in var.spoke_cidrs : cidr => cidr }
    content {
      src_cidr   = "0.0.0.0/0"
      dst_cidr   = snat_policy.value
      connection = "None"
      interface  = "eth0"
      protocol   = "all"
      snat_ips   = local.is_ha ? var.spoke_gw_object.ha_private_ip : "1.1.1.1"
    }
  }

  #SNAT policy for Egress NAT (e.g. for distributed FQDN egress on spoke GW)
  dynamic "snat_policy" {
    for_each = var.egress_nat ? { for cidr in var.spoke_cidrs : cidr => cidr } : {} #Only create SNAT policy if egress NAT is turned on.
    content {
      src_cidr   = snat_policy.value
      connection = "None"
      interface  = "eth0"
      protocol   = "all"
      snat_ips   = local.is_ha ? var.spoke_gw_object.ha_private_ip : "1.1.1.1"
    }
  }
}

resource "aviatrix_gateway_dnat" "dnat_rules_gw1" {
  count   = contains(keys(var.dnat_rules), "dummy") ? 0 : 1
  gw_name = var.spoke_gw_object.gw_name

  dynamic "dnat_policy" {
    for_each = var.dnat_rules
    content {
      src_cidr   = "0.0.0.0/0"
      dst_cidr   = dnat_policy.value.dst_cidr
      dnat_ips   = dnat_policy.value.dnat_ips
      dst_port   = try(dnat_policy.value.dst_port, null)
      protocol   = try(dnat_policy.value.protocol, null)
      dnat_port  = try(dnat_policy.value.dnat_port, null)
      connection = var.transit_gw_name
    }
  }

  dynamic "dnat_policy" {
    for_each = var.uturnnat ? var.dnat_rules : {} #Only create DNAT policy for U-Turn NAT if turned on
    content {
      src_cidr  = "0.0.0.0/0"
      dst_cidr  = dnat_policy.value.dst_cidr
      dnat_ips  = dnat_policy.value.dnat_ips
      dst_port  = try(dnat_policy.value.dst_port, null)
      protocol  = try(dnat_policy.value.protocol, null)
      dnat_port = try(dnat_policy.value.dnat_port, null)
      interface = "eth0"
    }
  }
}


resource "aviatrix_gateway_dnat" "dnat_rules_gw2" {
  count   = contains(keys(var.dnat_rules), "dummy") ? 0 : (local.is_ha ? 1 : 0)
  gw_name = var.spoke_gw_object.ha_gw_name

  dynamic "dnat_policy" {
    for_each = var.dnat_rules
    content {
      src_cidr   = "0.0.0.0/0"
      dst_cidr   = dnat_policy.value.dst_cidr
      dnat_ips   = dnat_policy.value.dnat_ips
      dst_port   = try(dnat_policy.value.dst_port, null)
      protocol   = try(dnat_policy.value.protocol, null)
      dnat_port  = try(dnat_policy.value.dnat_port, null)
      connection = var.transit_gw_name
    }
  }

  dynamic "dnat_policy" {
    for_each = var.uturnnat ? var.dnat_rules : {} #Only create DNAT policy for U-Turn NAT if turned on
    content {
      src_cidr  = "0.0.0.0/0"
      dst_cidr  = dnat_policy.value.dst_cidr
      dnat_ips  = dnat_policy.value.dnat_ips
      dst_port  = try(dnat_policy.value.dst_port, null)
      protocol  = try(dnat_policy.value.protocol, null)
      dnat_port = try(dnat_policy.value.dnat_port, null)
      interface = "eth0"
    }
  }
}
