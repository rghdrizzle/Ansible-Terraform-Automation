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

resource "tls_private_key" "ansible_key" { #to create a private for accessing the vm
  algorithm = "RSA"
  rsa_bits = 4096
}
resource "local_file" "ansiblekey" { # Storing the private key locally in a file
  filename="ansiblekey.pem"  
  content=tls_private_key.ansible_key.private_key_pem 
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
resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = "ansible"
  resource_group_name = var.rgname
  location            = var.rglocation
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"  
  network_interface_ids = [
    azurerm_network_interface.app_interface.id,
  ]
  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ansible_key.public_key_openssh
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface,
    tls_private_key.ansible_key
  ]
}





resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.SubnetA.id
  network_security_group_id = azurerm_network_security_group.netsg.id
  depends_on = [
    azurerm_network_security_group.netsg
  ]
}
