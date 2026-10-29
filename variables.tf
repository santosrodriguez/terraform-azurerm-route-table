variable "name" {
  description = "Explicit route table name. When null, use the generated CAF name."
  type        = string
  default     = null
}

variable "solution_name" {
  description = "Solution name included in the generated route table name."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Environment included in the generated route table name, such as dev, test, or prod."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the existing resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the route table."
  type        = string
}

variable "bgp_route_propagation_enabled" {
  description = "Whether to propagate routes learned through BGP."
  type        = bool
  default     = true
  nullable    = false
}

variable "tags" {
  description = "Tags applied to the route table."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "routes" {
  description = "Routes keyed by route name. Destinations accept CIDRs or Azure service tags."
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for route in values(var.routes) : contains([
        "VirtualNetworkGateway",
        "VnetLocal",
        "Internet",
        "VirtualAppliance",
        "None"
      ], route.next_hop_type)
    ])
    error_message = "Each route must specify a supported Azure next_hop_type."
  }

  validation {
    condition = alltrue([
      for route in values(var.routes) :
      route.next_hop_type == "VirtualAppliance" ? (
        can(cidrhost("${route.next_hop_in_ip_address}/32", 0))
      ) : route.next_hop_in_ip_address == null
    ])
    error_message = "VirtualAppliance routes require a valid IPv4 next-hop address; other next-hop types must omit it."
  }
}
