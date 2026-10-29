
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  lower   = false
  special = false
  numeric = true
}

resource "azurecaf_name" "name" {
  resource_type = "azurerm_route_table"
  suffixes      = [var.solution_name, var.location, var.environment, random_string.suffix.result]
}



resource "azurerm_route_table" "this" {
  name                          = var.name != null ? var.name : azurecaf_name.name.result
  resource_group_name           = var.resource_group_name
  location                      = var.location
  bgp_route_propagation_enabled = var.bgp_route_propagation_enabled
  tags                          = var.tags
}

resource "azurerm_route" "this" {
  for_each = var.routes

  name                   = each.key
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.this.name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}
