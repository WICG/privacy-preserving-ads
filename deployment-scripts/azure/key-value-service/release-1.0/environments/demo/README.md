# Demo Key Value Service Configurations for Azure

## Overview

This directory contains examples of Key Value Service terraform modules.

### Server Binary Runtime Flags

Numerous flags are consumed by the service binaries. The flags are specified via
**kv_services.yaml** file under `/services/app/helm`.

### Azure Architecture Flags

Running a stack in Azure requires a large number of parameters to be specified by the operator.
These parameters are all of the variables specified outside of the `runtime_flags` fields. For
descriptions, please refer to `../modules/kv-service/service_vars.tf`.

## Using the Demo Configuration

### Prerequisites

-   [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)
-   [Helm](https://helm.sh/docs/)
-   [Terraform](https://www.terraform.io/)

### Step 1: Configure Prerequisites

```shell
# Azure CLI
az login
az account set --subscription <your-azure-subscription>
az provider register -n Microsoft.ContainerInstance # Permission to allow ContainerInstance in subscription

# Terraform
export ARM_SUBSCRIPTION_ID=<your-azure-subscription-id>

# Kubernetes
export KUBE_CONFIG_PATH=/path/to/.kube/config
```

### Step 2: Create Azure Resources

You must have **Owner** role in subscription.

1. Create a sibling directory to `demo` (the directory hosting this file). It can be called
   anything, although naming it after your environment may be convenient. Example: `my_env`
2. Copy either ./kv-service to your directory. Example:

    ```text
         |-- environment
         |   |-- demo
         |   |   |-- kv-service
         |   |
         |   `-- my_env
         |       `-- kv-service
    ```

3. Set the copied my_env/kv-service as your new working directory.
4. Modify all of the variables in kv.tf
5. `terraform init && terraform apply` from within the kv-service directory.

### Step 3: Upload files for the Key Value Service

1. Go tp the Azure Storage account created by Terraform.
2. Upload data at the folders of the `fslogix` (`deltas` or `realtime`) file share.
