Heat is an orchestrator allowing the building of an infrastructure with a YAML file (called HOT:
Heat Orchestration Template) submitted by the user. This workshop will guide through the basic
concepts of Heat and the writing of simple templates.

# Preparation
## Software dependencies
By default the heat client is not installed with the `openstack` client. So you need to install it
manually.
```shell
apt-get install -y python-heatclient
```

You will surely need a text editor to create and edit the templates. If you go through this workshop
from a bounce server, do not hesitate to `apt-get install` your favorite terminal based text editor
otherwise you can use `pico` which is fairly simple.

## YAML format
If you are already familiar with the YAML format, skip this paragraph.

Otherwise, please consider reading an introduction to YAML. Some good resources include:
- http://sweetohm.net/article/introduction-yaml.en.html
- https://learnxinyminutes.com/docs/yaml/

Or just pick it up as we go, but this guide will assume you understand YAML at least a basic level.

# Create a stack
Every object that can manipulated by Heat is called a resource. Heat provides resources for probably
(sorry did not thoroughly check) all the objects the OpenStack API can handle.

Resources are assembled in a stack which is defined in a template. Easy.

## Simple template with one resource
To create a stack with only one instance, create a file named `one-vm.yaml` with the following
content:
```yaml
heat_template_version: 2016-10-14

description: Simple template to deploy a single instance

resources:
  my_instance:
    type: OS::Nova::Server
    properties:
      key_name: mykey
      image: Debian 9
      flavor: s1-2
      networks:
        - network: Ext-Net
```

This quite explicit, so let's create it:
```shell
$ openstack stack create --template one-vm.hot one-vm
+---------------------+---------------------------------------------+
| Field               | Value                                       |
+---------------------+---------------------------------------------+
| id                  | e6efc435-43ab-4ef2-a12c-e30cc380a5b2        |
| stack_name          | one-vm                                      |
| description         | Simple template to deploy a single instance |
| creation_time       | 2019-01-10T20:15:04Z                        |
| updated_time        | None                                        |
| stack_status        | CREATE_IN_PROGRESS                          |
| stack_status_reason | Stack CREATE started                        |
+---------------------+---------------------------------------------+
```

The stack is being created, you can check back the status of the deployment:
```shell
$ openstack stack show one-vm
+-----------------------+---------------------------------------------------------------+
| Field                 | Value                                                         |
+-----------------------+---------------------------------------------------------------+
| id                    | e6efc435-43ab-4ef2-a12c-e30cc380a5b2                          |
| stack_name            | one-vm                                                        |
| description           | Simple template to deploy a single instance                   |
| creation_time         | 2019-01-10T20:15:04Z                                          |
| updated_time          | None                                                          |
| stack_status          | CREATE_COMPLETE                                               |
| stack_status_reason   | Stack CREATE completed successfully                           |
| parameters            | OS::project_id: 3d6b19...                                     |
|                       | OS::stack_id: e6efc435-43ab-4ef2-a12c-e30cc380a5b2            |
|                       | OS::stack_name: one-vm                                        |
|                       |                                                               |
| outputs               | []                                                            |
|                       |                                                               |
| links                 | - href: https://orchestration.sbg5.cloud.ovh.net/v1/3d6b19... |
|                       |   rel: self                                                   |
|                       |                                                               |
| parent                | None                                                          |
| disable_rollback      | True                                                          |
| deletion_time         | None                                                          |
| stack_user_project_id | 9ddfeb...                                                     |
| capabilities          | []                                                            |
| notification_topics   | []                                                            |
| stack_owner           | None                                                          |
| timeout_mins          | None                                                          |
| tags                  | None                                                          |
+-----------------------+---------------------------------------------------------------+
```

You can check that a new instance has been created with the specs we defined in the template:
```shell
$ openstack server list
+--------------------------------------+---------------------------------+--------+---------------------------------------+----------+--------+
| ID                                   | Name                            | Status | Networks                              | Image    | Flavor |
+--------------------------------------+---------------------------------+--------+---------------------------------------+----------+--------+
| ec8916b8-7370-4366-8f24-2b59bde6bfbc | one-vm-my_instance-l3txn4ni6epr | ACTIVE | Ext-Net=xxx:yyy::zzz, XXX.XXX.XXX.XXX | Debian 9 | s1-2   |
+--------------------------------------+---------------------------------+--------+---------------------------------------+----------+--------+
```

> Although the OpenStack API won't prevent it, you should never modify or manage the resources
> created by Heat directly and always use the `stack` subcommand or template modification to change
> anything Heat related.

## Parametrized stack
Instead of fixed properties for your instance, you can add some parameters to pass to Heat when
creating the stack.

Let's edit the template to add some parameters:
```yaml
heat_template_version: 2016-10-14

description: Simple template to deploy a single instance

parameters:
  keypair:
    type: string
    label: Keypair
    description: Name of the key-pair to use for the instance
    default: mykey
  image:
    type: string
    label: Image
    description: Name (or ID) of the image to use for the instance
    default: Debian 9
  flavor:
    type: string
    label: Flavor
    description: Name (or ID) of the flavor to use for the instance
    default: s1-2

resources:
  my_instance:
    type: OS::Nova::Server
    properties:
      key_name: { get_param: keypair }
      image: { get_param: image }
      flavor: { get_param: flavor }
      networks:
        - network: Ext-Net
```

> The parameters section allows using default value so this template would create exactly the same
> stack as before if no parameters are passed at the creation.

Before creating a stack with this definition, let's clean the previous stack:
- :exclamation: **Task 1**: Delete the previous stack using `openstack stack delete one-vm`, and
check the instance has been removed.

You can now re-create the stack using the parameters:
```shell
$ openstack stack create \
    --template one-vm.hot \
    --parameter keypair=mykey \
    --parameter image='Ubuntu 18.04' \
    --parameter flavor=s1-4 \
    one-vm
```

Checking the list of instances should show that the instance has been created with the submitted
parameters.

## Output data after creation
When creating a stack with resources such as multiple instances, you might need to know right away
what IP addresses have been assigned to the instances without having to list them yourself.

Heat provides a way to ouput information about the stack it creates from your template.

Let's edit again the `one-vm.hot` template:
```yaml
heat_template_version: 2016-10-14

description: Simple template to deploy a single instance

parameters:
  keypair:
    type: string
    label: Keypair
    description: Name of the key-pair to use for the instance
    default: mykey
  image:
    type: string
    label: Image
    description: Name (or ID) of the image to use for the instance
    default: Debian 9
  flavor:
    type: string
    label: Flavor
    description: Name (or ID) of the flavor to use for the instance
    default: s1-2

resources:
  my_instance:
    type: OS::Nova::Server
    properties:
      key_name: { get_param: keypair }
      image: { get_param: image }
      flavor: { get_param: flavor }
      networks:
        - network: Ext-Net

outputs:
  public_ip:
    description: Public IP address of the instance
    value: { get_attr: [ my_instance, addresses, Ext-Net, 1 ] }
```

This time, instead of deleting and re-creating the stack, we can use one of the most powerful
command of heat: `stack update`.

This command will let you change the template of a stack and any parameter to pass to it and will
apply the differences automagically where needed.

First let's not be greedy and update only the template with the newly added outputs:
```shell
$ openstack stack create \
    --template one-vm.hot \
    --parameter keypair=mykey \
    --parameter image='Ubuntu 18.04' \
    --parameter flavor=s1-4 \
    one-vm
+---------------------+---------------------------------------------+
| Field               | Value                                       |
+---------------------+---------------------------------------------+
| id                  | 83e20957-fa79-4917-8d11-cd978c5d66b3        |
| stack_name          | one-vm                                      |
| description         | Simple template to deploy a single instance |
| creation_time       | 2019-01-10T20:48:34Z                        |
| updated_time        | 2019-01-10T21:13:34Z                        |
| stack_status        | UPDATE_IN_PROGRESS                          |
| stack_status_reason | Stack UPDATE started                        |
+---------------------+---------------------------------------------+
```

The update should be very quick and you can check its status and get the output this way:
```shell
$ openstack stack list
+--------------------------------------+------------+-----------------+----------------------+----------------------+
| ID                                   | Stack Name | Stack Status    | Creation Time        | Updated Time         |
+--------------------------------------+------------+-----------------+----------------------+----------------------+
| 83e20957-fa79-4917-8d11-cd978c5d66b3 | one-vm     | UPDATE_COMPLETE | 2019-01-10T20:48:34Z | 2019-01-10T21:13:34Z |
+--------------------------------------+------------+-----------------+----------------------+----------------------+

$ openstack stack output show --all one-vm
+-----------+------------------------------------------------------+
| Field     | Value                                                |
+-----------+------------------------------------------------------+
| public_ip | {                                                    |
|           |   "output_value": {                                  |
|           |     "OS-EXT-IPS-MAC:mac_addr": "fa:16:3e:05:0c:b2",  |
|           |     "version": 4,                                    |
|           |     "addr": "XXX.XXX.XXX.XXX",                       |
|           |     "OS-EXT-IPS:type": "fixed",                      |
|           |     "port": null                                     |
|           |   },                                                 |
|           |   "output_key": "public_ip",                         |
|           |   "description": "Public IP address of the instance" |
|           | }                                                    |
+-----------+------------------------------------------------------+
```

The command should return the public IPv4 of the instance.

> Note that the IPv6 is generally listed first and this is why the index in the output is `1`.

- :exclamation: **Task 2**: Update the stack with different parameters and check the results.

If you do not have a private network, please go through the workshop on [private
networks](../01_manage_resources_basic/01c_create_private_network_and_ports.md) before completing
the following task:
- :exclamation: **Task 3**: Modify the resource and the outputs to add a private network to the
    instance then update the stack.

If you need inspiration, you can check the [Heat Orchestration Template
specifications](https://docs.openstack.org/heat/latest/template_guide/hot_spec.html) or the
[resource types documentation](https://docs.openstack.org/heat/latest/template_guide/openstack.html).

Those documentation are very detailled and perhaps a selection of [template
examples](https://github.com/openstack/heat-templates) can help you best.
