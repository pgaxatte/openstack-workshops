First, let's move to the directory containing the plan:
```
cd ~/tf-openstack-workshops/small_infra
```

In this workshop you will start a small infrastructure with 3 instances. Each will have a dedicated
port and a volume attached.

# Initialization
Before being able to manipulate the infrastructure, terraform needs to be initialized:
```
terraform init
```

This will retrieve the providers needed by the plan we want to apply.

# Deploy
Deploy the infrastructure
```
terraform apply
```

This will create everything described in the plan.

Destroy it all:
```
terraform destroy
```
