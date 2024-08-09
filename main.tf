resource "azurerm_resource_group" "linux-dev-rg" {
  name     = "linux-dev"
  location = "uksouth"
  tags = {
    enviroment = "dev"
  }
}

resource "azurerm_virtual_network" "dev-vnet" {
  name                = "dev-vnet"
  resource_group_name = azurerm_resource_group.linux-dev-rg.name
  location            = azurerm_resource_group.linux-dev-rg.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    enviroment = "dev"
  }
}

resource "azurerm_subnet" "dev-subnet" {
  name                 = "subnet-1"
  resource_group_name  = azurerm_resource_group.linux-dev-rg.name
  virtual_network_name = azurerm_virtual_network.dev-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "dev-nsg" {
  name                = "dev-nsg"
  location            = azurerm_resource_group.linux-dev-rg.location
  resource_group_name = azurerm_resource_group.linux-dev-rg.name
  tags = {
    enviroment = "dev"
  }

  security_rule {
    name                       = "dev-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "dev-nsga" {
  subnet_id                 = azurerm_subnet.dev-subnet.id
  network_security_group_id = azurerm_network_security_group.dev-nsg.id
}

resource "azurerm_public_ip" "dev-ip" {
  name                = "dev-ip"
  resource_group_name = azurerm_resource_group.linux-dev-rg.name
  location            = azurerm_resource_group.linux-dev-rg.location
  allocation_method   = "Dynamic"

  tags = {
    enviroment = "dev"
  }
}

resource "azurerm_network_interface" "dev-nic" {
  name                = "dev-nic"
  location            = azurerm_resource_group.linux-dev-rg.location
  resource_group_name = azurerm_resource_group.linux-dev-rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dev-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dev-ip.id
  }
  tags = {
    enviroment = "dev"
  }
}

data "azurerm_shared_image" "linux-with-tools" {
  name                = "myImageDefinition"
  gallery_name        = "myGallery"
  resource_group_name = "myGalleryRG"
}

resource "azurerm_virtual_machine" "dev-vm" {
  name                = "dev-vm"
  resource_group_name = azurerm_resource_group.linux-dev-rg.name
  location            = azurerm_resource_group.linux-dev-rg.location

  vm_size               = "Standard_B1s"
  network_interface_ids = [azurerm_network_interface.dev-nic.id]
  storage_image_reference {
    id = data.azurerm_shared_image.linux-with-tools.id
  }

  storage_os_disk {
    name              = "dev-vm-osDick"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
}