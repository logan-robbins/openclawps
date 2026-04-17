locals {
  admin_ssh_public_key = file(pathexpand(var.admin_ssh_public_key_path))
  # Generated password used if the caller didn't supply one.
  generated_password = random_password.vm_password.result
  effective_password = var.admin_password != "" ? var.admin_password : local.generated_password

  cloud_init = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    admin_username = var.admin_username
    admin_password = local.effective_password
  })
}

resource "random_password" "vm_password" {
  length           = 24
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#%*+-_="
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.vm_name}-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_network_security_group" "this" {
  name                = "${var.vm_name}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_source_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.allowed_source_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Sunshine-TCP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["47984", "47989", "47990", "48010"]
    source_address_prefix      = var.allowed_source_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Sunshine-UDP"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_ranges    = ["47998", "47999", "48000", "48002"]
    source_address_prefix      = var.allowed_source_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "this" {
  name                = "${var.vm_name}-pip"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "this" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = var.vm_name
  computer_name                   = var.vm_name
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = local.effective_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.this.id]
  # AMD marketplace image does not support Trusted Launch (no signed kernel/driver chain).
  custom_data = base64encode(local.cloud_init)
  tags        = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.admin_ssh_public_key
  }

  # AMD Radeon Pro V710 marketplace image: Ubuntu with the AMD GPU driver
  # pre-installed, signed for Secure Boot, kernel pinned to a version the
  # driver builds against. Dodges the whole amdgpu blacklist + kernel drift
  # mess of installing the driver ourselves on stock Ubuntu.
  source_image_reference {
    publisher = "amdinc1746636494855"
    offer     = "nvv5_v710_linux_rocm_image"
    sku       = "planid125"
    version   = "1.0.2"
  }

  plan {
    name      = "planid125"
    product   = "nvv5_v710_linux_rocm_image"
    publisher = "amdinc1746636494855"
  }

  # AMD marketplace image ships a 512 GB OS disk; can only grow, not shrink.
  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
}
