Terraform is able to create infrastucture based on a description of resources called a plan. This
plan is written in a specific language (HCL).

Terraform relies on providers in order to know how to speak to the IAAS components we want to
manage. For instance in this workshop, Terraform will be speaking to OpenStack's API via its
openstack provider.

# Preparation

First you need to get the sources of the terraform plans we want to use for this workshop:
```
git clone https://github.com/pgaxatte/tf-openstack-workshops ~/tf-openstack-workshops
```

Now you can proceed to the first [deployment](04b_terraform_small_infra.md).
