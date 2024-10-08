# Demo Buyer and Seller Terraform Configurations for Azure

## Overview

This directory contains examples of the buyer and seller terraform modules.

The operator of a buyer or seller service pair (SellerFrontEnd + Auction and BuyerFrontEnd +
Bidding, henceforth referred to as 'stack') will deploy the services using terraform. The
configuration of the buyer and seller modules has many different fields, so this directory is aimed
at serving as a guide for the operator trying to bring up a fully functioning stack. The seller
stack is meant to communicate with a seller ad service and buyer front ends; the buyer stack is
expected to communicate only with seller front ends.

## Configuration

Each stack has two major configuration components.

### Server Binary Runtime Flags

Numerous flags are consumed by the service binaries. The flags are specified via **buyer.yaml** and
**seller.yaml** files under `/services/app/helm`. Because each service consumes many unique flags,
there are two sources to check in order to gain a full understanding of each flag:

1. In the codebase, please familiarize yourself with `services/<service_name>/runtime_flags.h` (such
   as `services/auction_service/runtime_flags.h`). These header files serve as the ultimate source
   of truth for the flags unique to the service. For descriptions of each flag, you can search their
   corresponding `ABSL_FLAG` definition (typically the name of the flag but all snakecase). For
   usage of each flag, consider searching the codebase for the flag name in all uppercase.
1. For flags common to all services, please inspect
   `services/common/constants/common_service_flags.h`. For learning more about these flags and how
   these integrate with the codebase, you can use the same principles as from step 1. For examples,
   please refer to `./buyer/buyer.tf` and `./seller/seller.tf`.

### Azure Architecture Flags

Running a stack in Azure requires a large number of parameters to be specified by the operator.
These parameters are all of the variables specified outside of the `runtime_flags` fields. For
descriptions, please refer to `../modules/buyer/service_vars.tf` and
`../modules/seller/service_vars.tf`. For examples, please refer to `./buyer/buyer.tf` and
`./seller/seller.tf`.

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

1.  Create a sibling directory to `demo` (the directory hosting this file). It can be called
    anything, although naming it after your environment may be convenient. Example: `my_env`
2.  Copy either ./buyer or ./seller to your directory. Example:

         |-- environment
         |   |-- demo
         |   |   |-- buyer
         |   |   `-- seller
         |   `-- my_env
         |       `-- seller

3.  Set the copied buyer or seller directory as your new working directory.
4.  Modify all of the variables in buyer.tf or seller.tf.
5.  `terraform init && terraform apply` from within the buyer or seller directory.
    -   **Buyer** deploys the **bidding** and **buyer frontend** service.
    -   **Seller** deploys the **auction** and **seller frontend** service.
