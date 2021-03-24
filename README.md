## SQL Server with Private Networking 
Terraform scripts to create a SQL Server and Azure SQL Database connected to a private VNET. 

### Resources created
- Resource group
- Virtual network
    - 2 subnets
    - Private link for SQL DB
    - DNS zone for private link
    - NIC for priavte link
- Virtual machine
    - SQL 2017 / Windows Server image
    - SQL Server extension
    - NIC
    - NSG - Firewall opened for specified IP for SQL and RDP
    - Reserved public IP / dns name
    - OS Disk
- SQL Database
    - Database server - Firewall opened for specified IP
    - Database - initialized from specified backup
    - Storage account for logs

### Files
- main.tf - Primary Terraform file - Creates resource group and gets the key for the storage account where the database bacpac resides
- sqldb.tf - Creates Azure SQL Server, DB and imports bacpac from storage account
- sqlvm.tf - Creates SQL Server VM
- vnet.tf - Creates VNET, NSG, subnets and private endpoint
- variables.tf - Defines input variables

#### To run locally, you also need to create:
- variables.tfvars - Stored values for all input variables in the format ***varname=value***
- backend.tfvars - Stored values for Azure backend state storage in the format ***configuration=value***
    ```
    resource_group_name = "rgname"
    storage_account_name = "storageacctname"
    container_name = "containername"
    key = "statefilename.tfstate"
    ```

### To create the environment run the following commands

```terraform init -backend-config=backend.tfvars```

```terraform plan -var-file variables.tfvars```

```terraform apply -var-file variables.tfvars```

### To destroy the environment run 

```terraform destroy -var-file variables.tfvars```