AzureRM Provider – Features Block
What is features {} in Terraform?

The features {} block is a required configuration block in the AzureRM provider. Even if it is empty, we must include it because the provider expects it.

If we need to customize specific behaviors, we can add feature settings inside it.

Important: An empty features {} block does not perform a special action by itself. It satisfies the provider's configuration requirement. The settings inside it customize the provider's behavior.

Basic Example
provider "azurerm" {
  features {}
}

Example with Resource Group Protection
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}


Explanation:

provider "azurerm" tells Terraform to use the AzureRM provider to manage Azure resources.
features {} provides the required feature configuration block.
resource_group configures resource-group-related behavior.
prevent_deletion_if_contains_resources = true prevents the AzureRM provider from deleting a resource group when it still contains resources.
Difference Between features {} and prevent_destroy
features {} is a provider configuration block.
prevent_deletion_if_contains_resources is an AzureRM provider setting that protects resource groups containing resources.
prevent_destroy = true is a Terraform lifecycle rule that prevents Terraform from destroying a particular resource while that rule remains in the configuration.
Key Takeaway

The empty features {} block satisfies the AzureRM provider's configuration requirement. Adding settings inside it allows us to customize specific resource-management behaviors.
