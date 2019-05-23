This workshop will help manage some network resources of the cloud.

Pre-requisites: you need a project with vRack activated.

You will be dealing with 3 different components:
- **networks** (approximatively) represent the [layer 2](https://en.wikipedia.org/wiki/Data_link_layer) in the OSI model
- **subnets** are encapsulated in the networks and carry the [layer 3](https://en.wikipedia.org/wiki/Network_layer) information
- **ports** represent the link between an instance and a subnetwork. This is the virtual cable connecting the instance to the network.

# Create a private network
By default only a public network is provided but some use case require the instances to be connected on a dedicated private network.

OpenStack provides this functionality and it is implemented at OVH using a technology named vRack. Without going into the details,
vRack provides an isolated network that spans across regions and can be used to connect any instance and even dedicated servers.

Let's start by simply creating a network which will be an empty envelope carrying very few information:
```shell
openstack network create mypriv01
```

This will output some information about the network, for instance:
```
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | UP                                   |
| availability_zone_hints   |                                      |
| availability_zones        |                                      |
| created_at                | 2019-01-03T17:04:26Z                 |
| description               |                                      |
| dns_domain                | None                                 |
| id                        | 84cad8f5-e07b-412f-982f-4c7f332cdea1 |
| ipv4_address_scope        | None                                 |
| ipv6_address_scope        | None                                 |
| is_default                | None                                 |
| is_vlan_transparent       | None                                 |
| mtu                       | 9000                                 |
| name                      | mypriv01                             |
| port_security_enabled     | False                                |
| project_id                | 88c866...                            |
| provider:network_type     | vrack                                |
| provider:physical_network | None                                 |
| provider:segmentation_id  | 2700                                 |
| qos_policy_id             | None                                 |
| revision_number           | 2                                    |
| router:external           | Internal                             |
| segments                  | None                                 |
| shared                    | False                                |
| status                    | ACTIVE                               |
| subnets                   |                                      |
| tags                      |                                      |
| updated_at                | 2019-01-03T17:04:26Z                 |
+---------------------------+--------------------------------------+
```

This will allow the creation of a subnet to define a range of IP that should be used.
Here we will use a /24 IPv4 network which will provide 253 usable addresses:
```shell
openstack subnet create \
    --network mypriv01 \
    --subnet-range 10.0.0.0/24 \
    --allocation-pool start=10.0.0.2,end=10.0.0.254 \
    --gateway none \
    --dns-nameserver 0.0.0.0 \
    mysub01
```

> Note that since this a private network, there is no gateway. Also it is mandatory to add a DNS
> nameserver to 0.0.0.0 to prevent the DHCP server to send bad DNS in the DHCP reply.

The result of this command will look like:
```
+-------------------+--------------------------------------+
| Field             | Value                                |
+-------------------+--------------------------------------+
| allocation_pools  | 10.0.0.2-10.0.0.254                  |
| cidr              | 10.0.0.0/24                          |
| created_at        | 2019-01-03T17:09:20Z                 |
| description       |                                      |
| dns_nameservers   | 0.0.0.0                              |
| enable_dhcp       | True                                 |
| gateway_ip        | None                                 |
| host_routes       |                                      |
| id                | cc7a966e-8f39-44d0-b067-cd191bb07ac6 |
| ip_version        | 4                                    |
| ipv6_address_mode | None                                 |
| ipv6_ra_mode      | None                                 |
| name              | mysub01                              |
| network_id        | 84cad8f5-e07b-412f-982f-4c7f332cdea1 |
| project_id        | 88c866...                            |
| revision_number   | 2                                    |
| segment_id        | None                                 |
| service_types     |                                      |
| subnetpool_id     | None                                 |
| tags              |                                      |
| updated_at        | 2019-01-03T17:09:20Z                 |
+-------------------+--------------------------------------+
```

Now we can take a look at the available networks and see the public network along its subnet(s) and the newly created private
network with the new subnet:
```shell
openstack network list
```

Which outputs:
```
+--------------------------------------+----------+----------------------------------------------------------------------------+
| ID                                   | Name     | Subnets                                                                    |
+--------------------------------------+----------+----------------------------------------------------------------------------+
| 581fad02-...                         | Ext-Net  | 634a92e0-..., 98de7b3b-...                                                 |
| 84cad8f5-e07b-412f-982f-4c7f332cdea1 | mypriv01 | cc7a966e-8f39-44d0-b067-cd191bb07ac6                                       |
+--------------------------------------+----------+----------------------------------------------------------------------------+
```

## Create two VM connected to the private network
Now that we have a private network, we can use the following command to create 2 new VM in one shot with a connection to both networks:
```shell
openstack server create \
    --image 'Debian 9' \
    --flavor s1-2 \
    --key-name mykey \
    --nic net-id=581fad02-... \
    --nic net-id=84cad8f5-... \
    --min 2 \
    --max 2 \
    myvmpriv
```
> Be sure to replace the net-id arguments with the id of your public network and your private network


You should now have 2 new instances named `myvmpriv-XXX`:
```shell
$ openstack server list
+--------------------------------------+------------+--------+------------------------------------------------------------+----------+--------+
| ID                                   | Name       | Status | Networks                                                   | Image    | Flavor |
+--------------------------------------+------------+--------+------------------------------------------------------------+----------+--------+
| 2040e150-ae5b-4b51-a218-36ca7f600784 | myvmpriv-2 | ACTIVE | Ext-Net=2001:xxx::yyy, 51.XXX.YYY.ZZZ; mypriv01=10.0.0.168 | Debian 9 | s1-2   |
| 4bd6c328-ff7c-4577-8df5-ff749d25b4e6 | myvmpriv-1 | ACTIVE | Ext-Net=2001:xxx::yyy, 51.XXX.YYY.ZZZ; mypriv01=10.0.0.197 | Debian 9 | s1-2   |
+--------------------------------------+------------+--------+------------------------------------------------------------+----------+--------+
```

As you can see the 2 VM have a public and a private IPv4 address.

Let's verify that the instances can see each other on the private network:
```shell
# With the public IP address of myvmpriv-1
$ ssh debian@XXX.XXX.XXX.XXX
[...]
debian@myvmpriv-1:~$
# Once on the instance let's install nmap to check the surrounding network
debian@myvmpriv-1:~$ sudo apt-get update && sudo apt-get install -y nmap
[...]
# Run a ping scan on the entire private network
debian@myvmpriv-1:~$ sudo nmap -sP 10.0.0.0/24

Starting Nmap 7.40 ( https://nmap.org ) at 2019-01-07 19:21 UTC
Nmap scan report for 10.0.0.2
Host is up (-0.20s latency).
MAC Address: FA:16:3E:A3:74:8C (Unknown)
Nmap scan report for 10.0.0.3
Host is up (-0.15s latency).
MAC Address: FA:16:3E:E6:5F:F1 (Unknown)
Nmap scan report for 10.0.0.168
Host is up (-0.15s latency).
MAC Address: FA:16:3E:6E:6A:F5 (Unknown)
Nmap scan report for 10.0.0.197
Host is up.
Nmap done: 256 IP addresses (4 hosts up) scanned in 5.95 seconds
```

It seems that 4 IP addresses have showed up. You can see the two private IP attributed to the instances along with 2 others.

- :exclamation: **Task 1**: Find out what is behind those unexpected IP addresses.

> Hint: take a look at the `ports` of your project: `openstack port list` and `openstack port show` should help you.

# Hotplug ports
The same goes for the network ports as for the volumes: instead of unplugging an external hard-drive from one machine to plug it
to another, just imagine you unplug a network card and its cable and plug it back into another machine.

The advantage of creating a network port separately is that a port will be assigned an IP address on
creation and will retain it as long as the port is not deleted.

## Create a port
So let's add a port to it with an IP address that we choose beforehand: `10.0.0.100`.

To create the port you will need the subnet and network id so first you should run:
```shell
openstack subnet list
```

Now you can create a new port with a predetermined address:
```shell
openstack port create --fixed-ip subnet=cc7a966e-...,ip-address=10.0.0.100 --network 84cad8f5-... myport
```

The new port should appear as `DOWN` in the list returned by `openstack port list`.

## Plug the port to a new VM
First let's create two new VM that do not have a private network interface:
```shell
openstack server create \
    --image 'Debian 9' \
    --flavor s1-2 \
    --key-name mykey \
    --nic net-id=581fad02-... \
    --min 2 \
    --max 2 \
    noprivvm
```

> Be careful to specify the id of the public (Ext-Net) network and not the private one.

Let's plug the port we created to the `noprivvm-1` instance.

First you need the ID of the port you just created. You can find it with the following command:
```shell
# To search and display as list:
openstack port list --fixed-ip ip-address=10.0.0.100

# Or just select the ID:
openstack port list -f value -c ID --fixed-ip ip-address=10.0.0.100
```

Now, using this ID, we can add it to an instance:
```shell
openstack server add port noprivvm-1 c695b5d8-...
```

You can check that:
- the `novmpriv-1` VM has now a second IP address on the private network:
```shell
openstack server show noprivvm-1
```
- the port is now `UP` and the `device_id` matches the ID of the VM:
```shell
openstack port show c695b5d8-...
```

## Move the port to another VM

Now let's detach the private port of `novmpriv-1` and attach it to `novmpriv-2`.

So first you need to remove the port from `novmpriv-1`:
```shell
openstack server remove port noprivvm-1 c695b5d8-...
```

Check that the port is still there with a status `DOWN`:
```shell
openstack port show c695b5d8-...
```

We can finally re-attach the port to `novmpriv-2`:
```shell
openstack server remove port noprivvm-2 c695b5d8-...
```

A quick look at the instance should confirm the port is connected:
```shell
openstack server show noprivvm-2
```

But the IP would still not be reachable because the hotplugging of an interface does not work out
of the box on the Debian 9 image. So you need to connect to `novmpriv-2` and run a DHCP client on
the new interface to get connectivity:
```shell
# With the public IP address of novmpriv-2
$ ssh debian@XXX.XXX.XXX.XXX
[...]
debian@novmpriv-2:~$

# List the interfaces of the VM
# You should see an interface ens7 down (could be a different interface name)
debian@novmpriv-2:~$ ip address list

# Run a DHCP client on this interface
debian@novmpriv-2:~$ sudo dhclient ens7

# It should now be up with the correct IP
debian@novmpriv-2:~$ ip address list
```

# You're up
To finish this workshop, complete the following:
- :exclamation: **Task 2**: Connect to another VM with a private network (`myvmpriv-1` for instance)
    and verify you can ping the IP of the port that has been moved.
- :exclamation: **Task 3**: Create a new port but on the public network, attach it to a VM and make
    sure you can ping it.
- :exclamation: **Task 4**: Can you come up with scenarios where moving a port from a VM to another is essential?

You finished the first workshop, you can now move on the [advanced resource management workshop](../02_manage_resources_advanced/02a_snapshots.md)
