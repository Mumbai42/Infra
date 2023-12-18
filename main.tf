resource "azurerm_resource_group" "rgname" {
  name     = local.rgname
  location = local.location
}

resource "azurerm_virtual_network" "newvnet" {
  name                = "network678"
  address_space       = ["10.0.0.0/16"]
  location            = local.location
  resource_group_name = local.rgname
  depends_on = [ azurerm_resource_group.rgname ]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rgname.name
  virtual_network_name = azurerm_virtual_network.newvnet.name
  address_prefixes     = ["10.0.2.0/24"]
  depends_on = [ azurerm_resource_group.rgname,azurerm_virtual_network.newvnet ]
}

resource "azurerm_network_interface" "newnic" {
  name                = "newnic"
  location            = local.location
  resource_group_name = local.rgname

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.publicip1.id
  }
  depends_on = [ azurerm_resource_group.rgname,azurerm_virtual_network.newvnet,azurerm_subnet.subnet1 ]
}

resource "azurerm_linux_virtual_machine" "newvm" {
  name                = "vm04"
  resource_group_name = local.rgname
  location            = local.location
  size                = "Standard_F2"

  admin_username = "adminuser"
  admin_password = "P@$$w0rd1234!"

  network_interface_ids = [
    azurerm_network_interface.newnic.id,
  ]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  depends_on = [ azurerm_network_interface.newnic,azurerm_resource_group.rgname ]
  disable_password_authentication = false
}
resource "azurerm_public_ip" "publicip1" {
  name                = "newpublicip"
  resource_group_name = local.rgname
  location            = local.location
  allocation_method   = "Static"
  depends_on = [ azurerm_resource_group.rgname ]
}