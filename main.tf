resource "aviatrix_gateway_snat" "gw_1" {
  gw_name    = var.spoke_gw_object.gw_name
  sync_to_ha = false
  snat_mode  = "customized_snat"

  dynamic "snat_policy" {
    for_each = { for cidr in var.spoke_cidrs : cidr => cidr }
    content {
      src_cidr   = snat_policy.value
      dst_cidr   = "0.0.0.0/0"
      connection = var.transit_gw_name
      interface  = "eth0"
      protocol   = "all"
      snat_ips   = var.gw1_snat_addr
    }
  }

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
}

resource "aviatrix_gateway_snat" "gw_2" {
  count      = local.is_ha ? 1 : 0
  gw_name    = var.spoke_gw_object.ha_gw_name
  sync_to_ha = false
  snat_mode  = "customized_snat"

  dynamic "snat_policy" {
    for_each = { for cidr in var.spoke_cidrs : cidr => cidr }
    content {
      src_cidr   = snat_policy.value
      dst_cidr   = "0.0.0.0/0"
      connection = var.transit_gw_name
      interface  = "eth0"
      protocol   = "all"
      snat_ips   = var.gw2_snat_addr
    }
  }

  dynamic "snat_policy" {
    for_each = { for cidr in var.spoke_cidrs : cidr => cidr }
    content {
      src_cidr   = "0.0.0.0/0"
      dst_cidr   = snat_policy.value
      connection = "None"
      interface  = "eth0"
      protocol   = "all"
      snat_ips   = var.spoke_gw_object.ha_private_ip
    }
  }
}

resource "aviatrix_gateway_dnat" "dnat_rules" {
  gw_name    = var.spoke_gw_object.gw_name
  sync_to_ha = true

  dynamic "dnat_policy" {
    for_each = var.dnat_rules
    content {
      src_cidr   = "0.0.0.0/0"
      dst_cidr   = dnat_policy.value.vip
      dst_port   = dnat_policy.value.port
      protocol   = dnat_policy.value.protocol
      dnat_ips   = dnat_policy.value.ip
      dnat_port  = dnat_policy.value.port
      connection = var.transit_gw_name
    }
  }
}
