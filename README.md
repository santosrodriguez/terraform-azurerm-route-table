# Azure Route Table Terraform Module

## Overview

This module creates an Azure route table and optional user-defined routes in an existing resource group.

## What This Module Deploys

- One `azurerm_route_table` with a generated CAF name (or an explicit name override), region, tags, and BGP propagation setting.
- One `random_string` suffix and one `azurecaf_name` resource for naming.
- One `azurerm_route` per entry in `routes`, using each map key as the route name.

Resource groups, virtual appliances, and subnet associations are managed separately.

## Requirements

| Requirement | Details |
|---|---|
| Terraform | Version constraint is not explicitly defined in the supplied code. |
| AzureRM provider | Declares `hashicorp/azurerm`, `hashicorp/random`, and `aztfmod/azurecaf`; provider version constraints are not explicitly defined in the supplied code. Configure the provider in the calling configuration. |
| Resource group | Must already exist. |
| Authentication and permissions | Configure Azure authentication in the calling provider. Specific permissions are not explicitly defined in the supplied code. |

## Required Parameters

| Name | Type | Description |
|---|---|---|
| `solution_name` | `string` | Solution name included in the generated name. Cannot be null. |
| `environment` | `string` | Environment included in the generated name. Cannot be null. |
| `resource_group_name` | `string` | Name of the existing resource group. |
| `location` | `string` | Azure region for the route table. |

## Optional Parameters

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | `null` | Explicit route table name override; null uses the generated CAF name. |
| `bgp_route_propagation_enabled` | `bool` | `true` | Whether to propagate routes learned through BGP. Cannot be null. |
| `tags` | `map(string)` | `{}` | Tags applied to the route table. Cannot be null. |
| `routes` | `map(object({ address_prefix = string, next_hop_type = string, next_hop_in_ip_address = optional(string) }))` | `{}` | Routes keyed by route name. Cannot be null. The optional next-hop address defaults to null. |

`address_prefix` accepts a CIDR or Azure service tag. Supported `next_hop_type` values are `VirtualNetworkGateway`, `VnetLocal`, `Internet`, `VirtualAppliance`, and `None`.

`VirtualAppliance` routes require a valid IPv4 `next_hop_in_ip_address`. Other next-hop types must omit this address or set it to null. No inputs are declared sensitive. Required inputs do not explicitly disable nullability.

## Default Parameter Values

| Parameter | Default Value | Purpose |
|---|---|---|
| `name` | `null` | Use the generated CAF name. |
| `bgp_route_propagation_enabled` | `true` | Enable BGP route propagation. |
| `tags` | `{}` | Apply no tags by default. |
| `routes` | `{}` | Create no individual routes by default. |

## Minimum Required Example

Use this local source path from the repository root (the parent directory of this module). Configure an authenticated AzureRM provider in the calling configuration and create the resource group beforehand.

```hcl
module "route_table" {
  source = "./route-table"

  solution_name       = "network"
  environment         = "dev"
  resource_group_name = "rg-network-dev"
  location            = "eastus"
}
```

This creates one route table with BGP propagation enabled and no individual routes. Adjust the source path when calling from another directory.

## Full Example

```hcl
module "route_table" {
  source = "./route-table"

  solution_name                 = "network"
  environment                   = "prod"
  name                          = "rt-prod-eastus"
  resource_group_name           = "rg-network-prod"
  location                      = "eastus"
  bgp_route_propagation_enabled = false

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }

  routes = {
    default-to-appliance = {
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.1.4"
    }
    block-example-network = {
      address_prefix = "192.0.2.0/24"
      next_hop_type  = "None"
    }
  }
}

output "route_table_id" {
  value = module.route_table.id
}
```

This disables BGP propagation, sends default traffic to a virtual appliance, and drops traffic to the example network. Replace sample names, destinations, and the appliance address with your network values. The resource group and appliance must exist separately; configure subnet associations separately as well.

## Outputs

| Name | Description |
|---|---|
| `id` | Resource ID of the route table. |
| `name` | Name of the route table. |
| `route_ids` | Route resource IDs keyed by route name; an empty map when no routes are supplied. |

No outputs are declared sensitive.

## Best Practices

- Use consistent names and tags for environment and ownership.
- Review prefixes, next hops, and BGP propagation before associating the table with subnets.
- Keep route map keys stable because they identify Terraform resource instances.
- Define Terraform and provider version constraints in the calling configuration and use secured remote state.

## Notes

By default, Azure CAF naming uses the route table resource type and suffixes in this order: solution name, location, environment, and a four-character random string with lowercase letters and digits. Set `name` to override the generated result. Naming resources are still created when an override is supplied. Changing naming inputs can rename the route table; review replacement actions in the plan. Routes reference the created route table directly, establishing their dependency on it. The module validates next-hop types and IPv4 appliance addresses but defines no destination-prefix validation.

The examples reflect the supplied source and have not been deployed to Azure.
