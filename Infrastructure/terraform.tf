terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rsg"
    storage_account_name = "jqtempsa"
    container_name       = "tfstate"
    key                  = "jeffsteruk.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
  tenant_id                  = "23094f0b-5e78-428d-a15e-d74f0eb71d6a"
  subscription_id            = "87f34df8-a283-4f56-bc04-6a5e214d516d"
  skip_provider_registration = true
  use_oidc                   = true
}
