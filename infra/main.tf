terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.59.0"
    }
  }
}
variable "rgname" {}
variable "rglocation" {}
provider "azurerm" {
    features {}
}
resource "azurerm_public_ip" "ip" {
  name                = "ansible-pip"
  location            = var.rglocation
  resource_group_name = var.rgname
  allocation_method   = "Static"
}

resource "azurerm_virtual_network" "main" {
  name                = "ansible-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.rglocation
  resource_group_name = var.rgname
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = var.rgname
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "neti" {
  name                = "ansible-nic"
  location            = var.rglocation
  resource_group_name = var.rgname

  ip_configuration {
    name                          = "testconfig-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip.id
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "ansible" {
  name                = "ansible-vmss"
  resource_group_name = var.rgname
  location            = var.rglocation
  sku                 = "Standard_F2"
  instances           = 2
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  network_interface {
    name    = "ansible"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.internal.id
      version = "IPv6"
    }
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}