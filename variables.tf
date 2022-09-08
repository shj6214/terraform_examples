variable "rg_name_prefix" {
  default     = "terraform-test-rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "service_location" {
  default     = "Korea Central"
  description = "Location of the resource group."
}

variable "dev_subnet_id" {
  description = "The subnet id of the virtual network where the virtual machines will reside."
  default     = "azurerm_subnet.terraformsubnet.id"
}

variable "dev_nsg_id" {
  description = "The subnet id of the virtual network where the virtual machines will reside."
  default     = "azurerm_network_security_group.nsg.id"
}

variable "vm_infos" {
  description = "vm infos"
  
  type        = map(any)
  
  default     = {
    "test-kc-vm01"   = {
      name                = "test-kc-vm01" 
      size                = "Standard_DS1_v2"
      admin_username      = "zncwork"
      admin_password      = "votmdnjem12#"
      resource_group_name = "test-kc-rg"
      location            = "Korea Central"
    }
    "test-kc-vm02"   = {
      name                = "test-kc-vm02"
      size                = "Standard_DS1_v2"
      admin_username      = "zncwork"
      admin_password      = "votmdnjem12#"
      resource_group_name = "test-kc-rg"
      location            = "Korea Central"
    }
  }
}


