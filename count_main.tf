provider "azurerm" {
  subscription_id = "20e48f57-d5dd-4ab1-afc1-c425d5f933a5"
  tenant_id = "785087ba-1e72-4e7d-b1d1-4a9639137a66"

  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name_prefix
  location = var.service_location
}

# Create virtual network
resource "azurerm_virtual_network" "terraform-vnet" {
  name                = "terraform-vnet"
  address_space       = ["172.16.0.0/16"]
  location            = var.service_location
  resource_group_name = var.rg_name_prefix
}

# Create subnet
resource "azurerm_subnet" "terraformsubnet" {
  name                 = "terraform-vnet-subnet"
  resource_group_name  = var.rg_name_prefix
  virtual_network_name = azurerm_virtual_network.terraform-vnet.name
  address_prefixes     = ["172.16.0.0/24"]
}

resource "azurerm_virtual_network_dns_servers" "dnsserver" {
  virtual_network_id = azurerm_virtual_network.terraform-vnet.id
  dns_servers        = ["172.16.0.10"]
}

# Create network interface
resource "azurerm_network_interface" "vm-nic" {
  name                = "terraform-vm-nic"
  location            = var.service_location
  resource_group_name = var.rg_name_prefix

  ip_configuration {
    name                          = "terraform-vm-ip"
    subnet_id                     = var.dev_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.16.0.5"
  }
}

# Create public IPs
resource "azurerm_public_ip" "pip" {
  # count               = 03
  # name                = "terraform-vm${count.index}-pip${count.index}"
  name                = "${azurerm_network_interface.vm-nic}-pip"
  location            = var.service_location
  resource_group_name = var.rg_name_prefix
  allocation_method   = "Static"
  sku                 = "Standard"
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "terraform-subnet-nsg"
  location            = var.service_location
  resource_group_name = var.rg_name_prefix

  security_rule {
    name                       = "SSH"
    priority                   = 4010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = ["123.141.145.21", "123.141.145.22", "123.141.145.23"]
    destination_address_prefix = "*"
    description                = "SSH 원격 포트 설정"
  }
  security_rule {
    name                       = "RDP"
    priority                   = 4020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefixes    = ["123.141.145.21", "123.141.145.22", "123.141.145.23"]
    destination_address_prefix = "*"
    description                = "RDP 원격 포트 설정"
  }
  security_rule {
    name                       = "Test"
    priority                   = 4030
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.0.0/24"
    destination_address_prefix = "*"
    description                = "TEST 포트 구성"
  }
}
########################※필수!!!!!
# source_address_prefix(단일)   = "*" / "123.141.145.21" 등등 CIDR 또는 IP 범위 또는 * 와 Tag 등으로 구성 가능
# source_address_prefixes(복수) = ["123.141.145.21/32","123.141.145.22/32","123.141.145.23/32"] IP 주소 접두사로 구성 가능

# Connect the security group to the network interface
resource "azurerm_subnet_network_security_group_association" "nsg_subnet" {
  subnet_id                 = var.dev_subnet_id
  network_security_group_id = var.dev_nsg_id
}


# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}



/*


# PPG Create
resource "azurerm_proximity_placement_group" "ppg" {
  name                = "terrafor-service-ppg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_availability_set" "terraform-avset" {
  name                         = "terraform-avset"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  proximity_placement_group_id = azurerm_proximity_placement_group.ppg.id
}


# Create virtual machine
resource "azurerm_windows_virtual_machine" "terraform-vm" {
  count                        = 03
  name                         = "terraform-vm${count.index}"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  network_interface_ids        = [element(azurerm_network_interface.vm-nic.*.id, count.index)]
  size                         = "Standard_F2s"
  computer_name                = "terraform-vm${count.index}"
  admin_username               = "zenuser"
  admin_password               = "rkskekfk1234!@"
  proximity_placement_group_id = azurerm_proximity_placement_group.ppg.id
  availability_set_id          = azurerm_availability_set.terraform-avset.id
  os_disk {
    name                 = "terraform-vm${count.index}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 256
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  boot_diagnostics {
    #enabled = "true"
    #storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }
}
*/

/*
# Create network interface
resource "azurerm_network_interface" "vm-nic" {
  count               = 03
  name                = "terraform-vm${count.index}-nic${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "terraform-vm-ip"
    subnet_id                     = azurerm_subnet.terraformsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.pip.*.id, count.index)
  }
}
*/