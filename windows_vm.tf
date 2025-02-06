variable "location" {
  default = "East US"
}

variable "vm_benito" {
  default = "windows-vm"
}

variable "admin_username" {
  default = "adminuser"
}

variable "admin_password" {
  default = "P@ssw0rd123"
}

# Ressource de groupe de ressources
resource "azurerm_resource_group" "rg_benito" {
  name     = "rg-windows-vm"
  location = var.location
}

# Ressource de réseau virtuel
resource "azurerm_virtual_network" "vnet_benito" {
  name                = "vnet-windows-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_benito.name
  address_space       = ["10.0.0.0/16"]
}

# Sous-réseau pour la machine virtuelle
resource "azurerm_subnet" "subnet_benito" {
  name                 = "subnet-windows-vm"
  resource_group_name  = azurerm_resource_group.rg_benito.name
  virtual_network_name = azurerm_virtual_network.vnet_benito.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Adresse IP publique pour la machine virtuelle
resource "azurerm_public_ip" "public_ip_benito" {
  name                = "public-ip-windows-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_benito.name
  allocation_method   = "Dynamic"
}

# Interface réseau de la machine virtuelle
resource "azurerm_network_interface" "nic_benito" {
  name                = "nic-windows-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_benito.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_benito.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_benito.id
  }
}

# Machine virtuelle Windows
resource "azurerm_virtual_machine" "benito_vm" {
  name                  = var.vm_benito
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_benito.name
  network_interface_ids = [azurerm_network_interface.nic_benito.id]
  vm_size               = "Standard_B1ms"  # Changez cette valeur selon vos besoins

  storage_os_disk {
    name          = "${var.vm_benito}-osdisk"
    caching       = "ReadWrite"
    create_option = "FromImage"
    os_type       = "Windows"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"  # Changez la version de Windows Server si nécessaire
    version   = "latest"
  }

  os_profile {
    computer_name  = var.vm_benito
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  tags = {
    environment = "production"
  }
}

output "public_ip" {
  value = azurerm_public_ip.public_ip_benito.ip_address
}
