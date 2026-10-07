# Configure Azure provider
provider "azurerm" {
  features {}
}

# ---------------------------------------------------------
# 1. Resource Group
# ---------------------------------------------------------

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-network-dev"
  location = "East US"
}

# ---------------------------------------------------------
# 2. Virtual Network
# ---------------------------------------------------------

# Create the Azure Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Overall IP range of the VNet
  address_space = ["10.0.0.0/16"]
}

# ---------------------------------------------------------
# 3. Public Subnet
# ---------------------------------------------------------

# Create a public subnet
# Example: Web servers / Load Balancer can be placed here
resource "azurerm_subnet" "public" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.1.0/24"]
}

# ---------------------------------------------------------
# 4. Private Subnet
# ---------------------------------------------------------

# Create a private subnet
# Example: Application servers / database-related workloads
resource "azurerm_subnet" "private" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.2.0/24"]
}

# ---------------------------------------------------------
# 5. Public Subnet NSG
# ---------------------------------------------------------

# Network Security Group for public subnet
resource "azurerm_network_security_group" "public_nsg" {
  name                = "nsg-public"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Allow SSH
  # In production, restrict source to corporate/VPN IP
  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "YOUR_IP/32"
    destination_address_prefix = "*"
  }

  # Allow HTTP
  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate public NSG with public subnet
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

# ---------------------------------------------------------
# 6. Private Subnet NSG
# ---------------------------------------------------------

# Network Security Group for private subnet
resource "azurerm_network_security_group" "private_nsg" {
  name                = "nsg-private"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Example: Allow application traffic from VNet
  security_rule {
    name                       = "allow-vnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# Associate private NSG with private subnet
resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

# ---------------------------------------------------------
# 7. Public IP for NAT Gateway
# ---------------------------------------------------------

# Create a public IP
# NAT Gateway uses this IP for outbound internet traffic
resource "azurerm_public_ip" "nat" {
  name                = "pip-nat"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"
}

# ---------------------------------------------------------
# 8. NAT Gateway
# ---------------------------------------------------------

# Create NAT Gateway
# Provides outbound internet access to private subnet
# without assigning public IPs to private VMs
resource "azurerm_nat_gateway" "nat" {
  name                = "nat-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "Standard"
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "nat" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# Associate NAT Gateway with private subnet
resource "azurerm_subnet_nat_gateway_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}
