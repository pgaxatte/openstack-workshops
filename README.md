This is a collection of workshops to learn how to use OpenStack on OVH Public Cloud (although it can be adapted easily to different cloud provider using OpenStack).

The workshops are organized as follows:
1. **Basic resource management**: simple manipulation of resources
  - [**01a**](01_manage_resources_basic/01a_boot_instances.md): List flavors, images, create a keypair and boot an instance
  - [**01b**](01_manage_resources_basic/01b_create_volumes.md): Create, attach and detach volumes
  - [**01c**](01_manage_resources_basic/01c_create_private_network_and_ports.md): Create networks, subnets and ports, attach and detach ports to/from instances


# Prerequisites
## For guided labs
Before beginning the workshops, the following elements should have been communicated to you:
- the IP address of the bounce server
- the password of the bounce user
- the ID of the container to use

### Connect to the container
With this information you can connect to the bounce server:
```shell
ssh bounce@XXX.XXX.XXX.XXX
```

The banner will ask to enter an ID:
```shell
bounce@XXX.XXX.XXX.XXX's password:
[...]
What is your ID? (desktop id or firstname.name)
<enter ID>
Connecting to ID's environement
root@XXXXXX:~#
```

You are now logged in.

### Install the openstack client
Once logged in you need to install the `openstack` command-line interface:
```shell
apt-get install python-openstackclient
```

Now let's add the completion for `bash`:
```shell
openstack complete > /etc/bash_completion.d/osc.bash_completion
source /etc/bash.bashrc
```

Finally, check and load the credentials of the OpenStack project that was prepared for you:
```shell
cat credentials
source credentials
```

Check that you have sufficient quotas to complete the workshops:
```shell
openstack quota show
```

Which should display a table containing the following information:
```
+----------------------+----------------------------------+
| Field                | Value                            |
+----------------------+----------------------------------+
| backup-gigabytes     | 1000                             |
| backups              | 10                               |
| cores                | 20                               |
| fixed-ips            | -1                               |
| floating_ips         | 0                                |
| gigabytes            | 20000                            |
| gigabytes_classic    | -1                               |
| gigabytes_high-speed | -1                               |
| health_monitors      | None                             |
| injected-file-size   | 10240                            |
| injected-files       | 5                                |
| injected-path-size   | 255                              |
| instances            | 20                               |
| key-pairs            | 25                               |
| l7_policies          | None                             |
| listeners            | None                             |
| load_balancers       | None                             |
| location             | None                             |
| name                 | None                             |
| networks             | 20                               |
| per-volume-gigabytes | 4000                             |
| pools                | None                             |
| ports                | 40                               |
| project              | fc55e5...                        |
| project_name         | 578385...                        |
| properties           | 128                              |
| ram                  | 40960                            |
| rbac_policies        | 10                               |
| routers              | 0                                |
| secgroup-rules       | 1000                             |
| secgroups            | 100                              |
| server-group-members | 10                               |
| server-groups        | 10                               |
| snapshots            | 40                               |
| snapshots_classic    | -1                               |
| snapshots_high-speed | -1                               |
| subnet_pools         | -1                               |
| subnets              | 20                               |
| volumes              | 40                               |
| volumes_classic      | -1                               |
| volumes_high-speed   | -1                               |
+----------------------+----------------------------------+
```

The minimum quotas that you will need for the workshops are:
- cores >= 6
- gigabytes >= 100
- instances >= 6
- key-pairs >= 1
- networks >= 2
- per-volume-gigabytes >= 10
- ram >= 25000
- snapshots >= 6
- subnets >= 4
- volumes >= 10


> :fireworks: Congratulations you are now ready to use OpenStack and complete the workshops.


## For other usage
For anyone else wanting to try this, you need:
- a valid OVH Public Cloud project
- a user on this project
- an openrc file for this user
- a terminal with the `openstack` CLI installed or use the terminal app integrated in the OVH manager.
