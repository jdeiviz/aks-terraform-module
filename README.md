# A complete AKS Terraform module

An example of Terraform module that creates an AKS cluster with the following:

- A Service Principal for AKS cluster
- Container log analytics enabled
- Advanced networking using an existing VNET enabled
- RBAC enabled to autenticate with Azure Active Directory and authorize with Kubernetes rolebindings
- A cluster admin group on Azure Active Directory
- A configured ACR to use in AKS cluster
- An Azurefile storage class
- Helm
- Private and public ingress controllers
- Certmanager that automates the digital certificates workflow with Let's Encrypt

# Usage

Example:
```javascript
module "aks" {
    source = "git::https://github.com/jdeiviz/aks-terraform-module.git"

    name = "<aksname>"
    environment = "dev"
    location = "northeurope"
    vnet_resource_group = "${data.azurerm_resource_group.rg.name}"
    vnet_name = "${azurerm_virtual_network.vnet.name}"
    vnet_subnet = "${azurerm_virtual_network.subnet.name}"
    acr_sku = "Premium"
    dns_prefix = "<aksname>"
    kubernetes_version = "1.11.5"
    count = "2"
    vm_size = "Standard_D2s_v3"
    max_pods = "70"
    os_type = "Linux"
    os_disk_size_gb = "50"
    admin_username = "<admin>"
    ssh_key_path = "~/.ssh/aks_dev.pub"
    cert_issuer_email = "<your@email.com>"
}
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](https://choosealicense.com/licenses/mit/)
