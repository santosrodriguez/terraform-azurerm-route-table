output "id" {
  description = "Resource ID of the route table."
  value       = azurerm_route_table.this.id
}

output "name" {
  description = "Name of the route table."
  value       = azurerm_route_table.this.name
}

output "route_ids" {
  description = "Route resource IDs keyed by route name."
  value = {
    for name, route in azurerm_route.this : name => route.id
  }
}
