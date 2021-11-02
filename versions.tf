terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.59.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = ">= 3.1.0"
    }
  }
  required_version = ">= 0.13"
}
