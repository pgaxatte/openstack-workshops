Install terraform
```
export TERRAFORM_VERSION=0.12.20
curl -Lo - https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip | gunzip -d - > /usr/local/bin/terraform
chmod +x /usr/local/bin/terraform
```

Initialize the terraform plugins and state:
```
terraform init
```

Deploy the infrastructure
```
terraform apply
```

Destroy it all:
```
terraform destroy
```
