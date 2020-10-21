resource "azurerm_resource_group" "rg" {
  name = "${local.prefix_snake}_rg"
  location = local.location
}