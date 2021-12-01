# Terraform file that creates resources for
# hosting a Linux virtual machine.

# Create azure provider
provider "azurerm" {
  features {}
}

# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create storage account
resource "azurerm_storage_account" "sa" {
  name                     = "${var.prefix}sa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}_vnet"
  address_space       = [var.address_space]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.address_prefix]
}

# Create public ip
resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  allocation_method   = "Static"
  domain_name_label   = var.hostname
}
output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

# Create network security group
resource "azurerm_network_security_group" "sg" {
  name                = "${var.prefix}_sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create nic
resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}_nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.prefix}-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.address_prefix,16)
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Create ssh key
resource "tls_private_key" "ssh_key" {
  algorithm   = "RSA"
  rsa_bits    = 2048
}

# Create Linux virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_F2"
  admin_username      = var.admin_username
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

}

# Create managed disk
resource "azurerm_managed_disk" "disk" {
  name                 = "${var.prefix}-disk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1
}

# Create disk attacher
resource "azurerm_virtual_machine_data_disk_attachment" "attacher" {
  managed_disk_id    = azurerm_managed_disk.disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = "10"
  caching            = "ReadWrite"
  
  provisioner "remote-exec" {
    # Run initialization script
    script = "init.sh"
    connection {
      type        = "ssh"
      host        = azurerm_public_ip.pip.fqdn
      user        = var.admin_username
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }
}