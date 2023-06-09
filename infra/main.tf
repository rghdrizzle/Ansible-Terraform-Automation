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

resource "azurerm_network_security_group" "netsg" {
  name                = "acceptanceTestSecurityGroup1"
  location            = var.rglocation
  resource_group_name = var.rgname

  security_rule {
    name                       = "ssh"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "ansible-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.rglocation
  resource_group_name = var.rgname
}

resource "azurerm_subnet" "SubnetA" {
  name                 = "internal"
  resource_group_name  = var.rgname
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "app_interface" {
  name                = "ansible"
  location            = var.rglocation
  resource_group_name = var.rgname

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.ip.id
  }

  depends_on = [
    azurerm_virtual_network.main,
    azurerm_public_ip.ip,
    azurerm_subnet.SubnetA
  ]
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

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
   network_interface {
    name    = "ansible"
    primary = true

    ip_configuration {
      name      = "internal"
      subnet_id = azurerm_subnet.SubnetA.id
    }
  }

}
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.SubnetA.id
  network_security_group_id = azurerm_network_security_group.netsg.id
  depends_on = [
    azurerm_network_security_group.netsg
  ]
}
