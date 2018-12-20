The goal of this workshop is to manipulate and manage instances.

Instances are virtual machines spawned by the cloud infrastructure at the demand of a client.

To boot a new instance you need to choose:
- a base image: *what OS should run in the VM?*
- a flavor: *what size the VM should be?* (i.e. how many vCPUs, how much RAM, how much disk space should we give it)
- an SSH keypair: by default password authentication is disabled so *what key should we use to login to the VM?*

We will see how to gather this information and boot some new instances.

# Boot a new instance
## Choose an image
First, let's choose a image in the list with the following command:
```shell
openstack image list
```

This will output a long table with some IDs and name of the available images:
```
+--------------------------------------+---------------------------------------------+--------+
| ID                                   | Name                                        | Status |
+--------------------------------------+---------------------------------------------+--------+
| de440dfc-e485-4657-b3c2-70437fed7eb7 | Archlinux                                   | active |
| 5b009590-34c0-4793-a93e-c6627df06097 | Centos 6                                    | active |
| [...]                                                                                       |
| d60f629d-7f22-4db8-9f4a-cf480a26856f | Debian 9                                    | active |
| [...]                                                                                       |
| 1068806a-7ca1-4c8a-8d6b-5f078cfa700a | rescue-ovh                                  | active |
+--------------------------------------+---------------------------------------------+--------+
```

**We will use an `Debian 9` for this workshop** but you could choose any GNU/Linux you like.

You can see the details of the image with the following command:
```shell
openstack image show 'Debian 9'

# Or using its id
openstack image show d60f629d-7f22-4db8-9f4a-cf480a26856f
```

## Choose a flavor
We need to determine the specifications of the VM we want to run. For this we need to choose a flavor in the list displayed by the following command:
```shell
openstack flavor list
```

The resulting output will be something similar to this:
```
+--------------------------------------+-----------------+--------+------+-----------+-------+-----------+
| ID                                   | Name            |    RAM | Disk | Ephemeral | VCPUs | Is Public |
+--------------------------------------+-----------------+--------+------+-----------+-------+-----------+
| 036e9748-b11e-427e-83af-407b2deee51b | win-b2-15       |  15000 |  100 |         0 |     4 | True      |
| 0b790592-f47c-4a52-ba56-3923a3013607 | c2-60-flex      |  60000 |   50 |         0 |    16 | True      |
| 0f7e0bf9-8100-4fd4-b238-29b1915481c4 | win-r2-15       |  15000 |   50 |         0 |     2 | True      |
| 119f1b5b-7744-43a5-bd40-bc54e18f1609 | c2-30           |  30000 |  200 |         0 |     8 | True      |
| 1a5fddab-4ddc-4619-ad29-09932b6bcb9f | r2-60           |  60000 |  100 |         0 |     4 | True      |
| [...]                                                                                                  |
```

This list is hard to read but we can sort the columns so let's just sort by VCPUs and choose a small flavor:
```shell
openstack flavor list --sort-column VCPUs | head
```

This gives:
```
+--------------------------------------+-----------------+--------+------+-----------+-------+-----------+
| ID                                   | Name            |    RAM | Disk | Ephemeral | VCPUs | Is Public |
+--------------------------------------+-----------------+--------+------+-----------+-------+-----------+
| 3c83dfbd-abdb-43d0-b041-3ac44009c2f7 | s1-4            |   4000 |   20 |         0 |     1 | True      |
| ce07016c-95df-4085-bb5a-565caffc2063 | s1-2            |   2000 |   10 |         0 |     1 | True      |
| 0f7e0bf9-8100-4fd4-b238-29b1915481c4 | win-r2-15       |  15000 |   50 |         0 |     2 | True      |
| 1faed731-1de8-4f04-97c0-e6e976c8445e | win-b2-7        |   7000 |   50 |         0 |     2 | True      |
| 2ed0b117-1b2a-4f86-bb76-05c20ae70298 | c2-7-flex       |   7000 |   50 |         0 |     2 | True      |
| 2ee71e14-d56f-47ff-8634-3ee532f5f191 | win-c2-7-flex   |   7000 |   50 |         0 |     2 | True      |
| 3b137bad-0d92-470d-9f19-3ee31e4da2db | win-r2-30       |  30000 |   50 |         0 |     2 | True      |
```

**For this workshop we will use `s1-4` flavors.**

You can see the details of the flavor with the following command:
```shell
openstack flavor show s1-4

# Or using its id
openstack flavor show 3c83dfbd-abdb-43d0-b041-3ac44009c2f7
```

## Use an SSH keypair
There is no SSH keypair available by default so we need to add one with the following command:
```shell
openstack keypair create --public-key /root/.ssh/id_rsa.pub mykey
```

You can list the available keypairs and see the detail of a keypair with the following commands:
```shell
openstack keypair list

# Display the detail of a keypair:
openstack keypair show mykey
```

## Finally, boot the instance
Now that you have all you need you can start a new instance with the following command:
```shell
openstack server create --image 'Debian 9' --flavor s1-4 --key-name mykey myvm01
```

This will output some information about the VM being started:
```
+-----------------------------+-----------------------------------------------------+
| Field                       | Value                                               |
+-----------------------------+-----------------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                              |
| OS-EXT-AZ:availability_zone |                                                     |
| OS-EXT-STS:power_state      | NOSTATE                                             |
| OS-EXT-STS:task_state       | scheduling                                          |
| OS-EXT-STS:vm_state         | building                                            |
| OS-SRV-USG:launched_at      | None                                                |
| OS-SRV-USG:terminated_at    | None                                                |
| accessIPv4                  |                                                     |
| accessIPv6                  |                                                     |
| addresses                   |                                                     |
| adminPass                   | ...                                                 |
| config_drive                |                                                     |
| created                     | 2018-12-21T14:01:07Z                                |
| flavor                      | s1-4 (3c83dfbd-abdb-43d0-b041-3ac44009c2f7)         |
| hostId                      |                                                     |
| id                          | 369ad246-8c48-40f9-ada1-269c0844b34c                |
| image                       | Debian 9 (d60f629d-7f22-4db8-9f4a-cf480a26856f)     |
| key_name                    | mykey                                               |
| name                        | myvm01                                              |
| progress                    | 0                                                   |
| project_id                  | 88c8667...                                          |
| properties                  |                                                     |
| security_groups             | name='default'                                      |
| status                      | BUILD                                               |
| updated                     | 2018-12-21T14:01:07Z                                |
| user_id                     | 12843a2...                                          |
| volumes_attached            |                                                     |
+-----------------------------+-----------------------------------------------------+
```

Notice that the `status` is `BUILD` and the `OS-EXT-STS:vm_state` field is `building`.
Also the field `addresses` is empty which means no IP address has been assigned to it yet.

You can run this command to check the progress of the VM:
```shell
openstack server show myvm01

# Or with its id:
openstack server show 369ad246-8c48-40f9-ada1-269c0844b34c
```

When the instance is ready you will see something similar to this:
```
+-----------------------------+----------------------------------------------------------+
| Field                       | Value                                                    |
+-----------------------------+----------------------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                                   |
| OS-EXT-AZ:availability_zone | nova                                                     |
| OS-EXT-STS:power_state      | Running                                                  |
| OS-EXT-STS:task_state       | None                                                     |
| OS-EXT-STS:vm_state         | active                                                   |
| OS-SRV-USG:launched_at      | 2018-12-21T14:01:32.000000                               |
| OS-SRV-USG:terminated_at    | None                                                     |
| accessIPv4                  |                                                          |
| accessIPv6                  |                                                          |
| addresses                   | Ext-Net=yyyy:yyyy:yyy::yyyy, XXX.XXX.XXX.XXX             |
| config_drive                |                                                          |
| created                     | 2018-12-21T14:01:07Z                                     |
| flavor                      | s1-4 (3c83dfbd-abdb-43d0-b041-3ac44009c2f7)              |
| hostId                      | cabbf89dbcae5f0c3c65c9698cf93de19100a46e983e594ff9001459 |
| id                          | 369ad246-8c48-40f9-ada1-269c0844b34c                     |
| image                       | Debian 9 (d60f629d-7f22-4db8-9f4a-cf480a26856f)          |
| key_name                    | mykey                                                    |
| name                        | myvm01                                                   |
| progress                    | 0                                                        |
| project_id                  | 88c8667...                                               |
| properties                  |                                                          |
| security_groups             | name='default'                                           |
| status                      | ACTIVE                                                   |
| updated                     | 2018-12-21T14:01:32Z                                     |
| user_id                     | 12843a2...                                               |
| volumes_attached            |                                                          |
+-----------------------------+----------------------------------------------------------+
```

`status` is now `ACTIVE` and an IPv4 and an IPv6 have been assigned to the instance

# Connect to the instance
Now you should be able to connect to the instance with SSH since we booted the instance with your SSH keypair:
```shell
ssh debian@XXX.XXX.XXX.XXX
```

> Generally the username is the name of the lowercase OS distribution name. You can find the username to use
> by looking at the image's properties with `openstack image show 'Debian 9'`. The `properties` line should
> show `image_original_user='debian'`.

Once logged in, let's replace `/etc/motd` (a.k.a Message Of The Day) to simulate some modifications on the instance:
```shell
debian@myvm01:~$ echo "This is myvm01" | sudo tee /etc/motd
```

Then logout with `exit` or `CTRL-D`

# You're up
Now, you should have enough information to complete the following task:
- :exclamation: **Task 1**: Create a new instance with a different flavor (s1-2 for instance) and a different motd

You can check the instances you have and their state with the following command:
```shell
openstack server list
```

Once this is done, proceed to the [next course](01b_create_volumes.md)
