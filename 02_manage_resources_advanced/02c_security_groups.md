This workshop is about the management of security groups and rules in your project.

Each instance's public network port can be protected by a set of rules defined in your project.

> Defining security rules on the private network is not (yet) supported at OVH.

The main attributes of the rules are:
- direction: `ingress` (external → VM) or `egress` (VM → external)
- ethertype: `IPv4` or `IPv6`
- protocol: `icmp`, `tcp`, `udp` or `None` for any
- remote IP / remote group: the address or group of addresses you consider as external (so the source for
ingress traffic or the destination for egress) or `None` for any
- dst port: destination port for TCP or UDP or `None` for any

These security rules are grouped in security groups and security groups are applied to instances
individually.

# Default rules
Before digging into how to create new rules and groups, let's take a look at the default sets of
rules:
```shell
$ openstack security group list
+--------------------------------------+---------+------------------------+----------------------+
| ID                                   | Name    | Description            | Project              |
+--------------------------------------+---------+------------------------+----------------------+
| 3109510a-15f6-4f4f-9276-0a0fc27fc4f9 | default | Default security group | fc55e5...            |
+--------------------------------------+---------+------------------------+----------------------+
```

This shows that there is only one set of rules named `default`. Let's take a closer look at this
group of rules:

```shell
$ openstack security group rule list default
+--------------------------------------+-------------+----------+------------+-----------------------+
| ID                                   | IP Protocol | IP Range | Port Range | Remote Security Group |
+--------------------------------------+-------------+----------+------------+-----------------------+
| 3153c809-0ce4-41e7-b57b-d6eb85ec50ab | None        | None     |            | None                  |
| 36ee8479-f113-44d4-b129-3b3c5133f2c4 | None        | None     |            | None                  |
| 47c47a41-2905-44f9-847e-bb5ea8ef9c33 | None        | None     |            | None                  |
| fc5552cf-69b1-4659-b40d-6aa74d62cf07 | None        | None     |            | None                  |
+--------------------------------------+-------------+----------+------------+-----------------------+
```

Since this is not very helpful, you can query more details:
```shell
$ openstack security group rule list default --long
+--------------------------------------+-------------+----------+------------+-----------+-----------+-----------------------+
| ID                                   | IP Protocol | IP Range | Port Range | Direction | Ethertype | Remote Security Group |
+--------------------------------------+-------------+----------+------------+-----------+-----------+-----------------------+
| 3153c809-0ce4-41e7-b57b-d6eb85ec50ab | None        | None     |            | egress    | IPv4      | None                  |
| 36ee8479-f113-44d4-b129-3b3c5133f2c4 | None        | None     |            | ingress   | IPv6      | None                  |
| 47c47a41-2905-44f9-847e-bb5ea8ef9c33 | None        | None     |            | ingress   | IPv4      | None                  |
| fc5552cf-69b1-4659-b40d-6aa74d62cf07 | None        | None     |            | egress    | IPv6      | None                  |
+--------------------------------------+-------------+----------+------------+-----------+-----------+-----------------------+
```

What you should understand from this list is that every kind of traffic is allowed in any direction
for IPv4 and IPv6.

So, by default, there is no filtering but if you remove the default rules, no traffic will be
allowed as the default policy is to block everything and security rules define what must be allowed.

# Manage security groups and rules
## Create a test VM
For the purpose of this workshop we need to spawn an instance that runs some service that should be
protected with a security rule. Let's create a `Debian 9` VM and run a simple webserver on it:
```shell
$ openstack server create \
    --image 'Debian 9' \
    --flavor s1-2 \
    --key-name mykey \
    --network Ext-Net \
    --wait \
    web01
$ ssh debian@XXX.XXX.XXX
debian@web01:~$ sudo apt-get update && sudo apt-get -y install apache2 ssl-cert

# Enable HTTPS too
debian@web01:~$ sudo a2enmod ssl
debian@web01:~$ sudo a2ensite default-ssl

# Restart apache
debian@web01:~$ sudo systemctl restart apache2

# Check it is listening on port 80 and 443
debian@web01:~$ ss -ntl
State      Recv-Q Send-Q  Local Address:Port  Peer Address:Port
LISTEN     0      128     *:22                *:*
LISTEN     0      128     :::80               :::*
LISTEN     0      128     :::22               :::*
LISTEN     0      128     :::443              :::*

# Highly customize the front page
debian@web01:~$ echo "This web01 VM" | sudo tee /var/www/html/index.html
debian@web01:~$ logout

# Check it is working for HTTP
$ curl http://XXX.XXX.XXX.XXX/
This web01 VM

# And for HTTPS
$ curl --insecure https://XXX.XXX.XXX.XXX/
This web01 VM
```

If you use the bounce container, try also from your computer to make sure it works everywhere.

We now have 2 services we can filter and test.

## Allow only SSH
As we saw the default rules allow all traffic to the VM so we need to remove it from the VM if we
want to be able to filter anything.

But before blocking all traffic by removing the default rules, we need at least a rule that allows
SSH connection from everywhere.

So let's create a security group:
```shell
$ openstack security group create --description 'Allow SSH from everywhere' allow-ssh
+-----------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Field           | Value                                                                                                                                                                      |
+-----------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| created_at      | 2019-01-10T09:11:55Z                                                                                                                                                       |
| description     | Allow SSH from everywhere                                                                                                                                                  |
| id              | 37bbb677-d4a9-4a5b-96d5-abe738ed9386                                                                                                                                       |
| name            | allow-ssh                                                                                                                                                                  |
| project_id      | fc55e5...                                                                                                                                                                  |
| revision_number | 1                                                                                                                                                                          |
| rules           | created_at='2019-01-10T09:11:55Z', direction='egress', ethertype='IPv4', id='cda87185-428d-4e27-a9e4-a73faeb8068a', revision_number='1', updated_at='2019-01-10T09:11:55Z' |
|                 | created_at='2019-01-10T09:11:55Z', direction='egress', ethertype='IPv6', id='0c5ad054-34c1-4baf-9455-ba2afa0aae0c', revision_number='1', updated_at='2019-01-10T09:11:55Z' |
| updated_at      | 2019-01-10T09:11:55Z                                                                                                                                                       |
+-----------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```

The command created a new group but also two rules, let's see what they do:
```shell
$ openstack security group rule list allow-ssh --long
+--------------------------------------+-------------+----------+------------+-----------+-----------+-----------------------+
| ID                                   | IP Protocol | IP Range | Port Range | Direction | Ethertype | Remote Security Group |
+--------------------------------------+-------------+----------+------------+-----------+-----------+-----------------------+
| 0c5ad054-34c1-4baf-9455-ba2afa0aae0c | None        | None     |            | egress    | IPv6      | None                  |
| cda87185-428d-4e27-a9e4-a73faeb8068a | None        | None     |            | egress    | IPv4      | None                  |
+--------------------------------------+-------------+----------+------------+-----------+-----------+-----------------------+
```

These two rules just allow any egress traffic but don't allow ingress so now we can add some rules
to it:
```shell
$ openstack security group rule create \
    --description 'Allow SSH in for any IPv4' \
    --ingress \
    --ethertype IPv4 \
    --protocol tcp \
    --dst-port 22 \
    allow-ssh
+-------------------+--------------------------------------+
| Field             | Value                                |
+-------------------+--------------------------------------+
| created_at        | 2019-01-10T09:38:26Z                 |
| description       | Allow SSH in for any IPv4            |
| direction         | ingress                              |
| ether_type        | IPv4                                 |
| id                | 1a36e202-de1d-4c75-9ac7-1b7721f9b725 |
| name              | None                                 |
| port_range_max    | 22                                   |
| port_range_min    | 22                                   |
| project_id        | fc55e5...                            |
| protocol          | tcp                                  |
| remote_group_id   | None                                 |
| remote_ip_prefix  | 0.0.0.0/0                            |
| revision_number   | 1                                    |
| security_group_id | 37bbb677-d4a9-4a5b-96d5-abe738ed9386 |
| updated_at        | 2019-01-10T09:38:26Z                 |
+-------------------+--------------------------------------+

# Do the same for IPv6
$ openstack security group rule create \
    --description 'Allow SSH in for any IPv6' \
    --ingress \
    --ethertype IPv6 \
    --protocol tcp \
    --dst-port 22 \
    allow-ssh
+-------------------+--------------------------------------+
| Field             | Value                                |
+-------------------+--------------------------------------+
| created_at        | 2019-01-10T09:42:29Z                 |
| description       | Allow SSH in for any IPv6            |
| direction         | ingress                              |
| ether_type        | IPv6                                 |
| id                | cd7cd1ad-94b2-42ca-9aed-ee2e34b600be |
| name              | None                                 |
| port_range_max    | 22                                   |
| port_range_min    | 22                                   |
| project_id        | fc55e5...                            |
| protocol          | tcp                                  |
| remote_group_id   | None                                 |
| remote_ip_prefix  | None                                 |
| revision_number   | 1                                    |
| security_group_id | 37bbb677-d4a9-4a5b-96d5-abe738ed9386 |
| updated_at        | 2019-01-10T09:42:29Z                 |
+-------------------+--------------------------------------+
```

Check the rules are correct:
```shell
$ openstack security group rule list allow-ssh --long
+--------------------------------------+-------------+-----------+------------+-----------+-----------+-----------------------+
| ID                                   | IP Protocol | IP Range  | Port Range | Direction | Ethertype | Remote Security Group |
+--------------------------------------+-------------+-----------+------------+-----------+-----------+-----------------------+
| 0c5ad054-34c1-4baf-9455-ba2afa0aae0c | None        | None      |            | egress    | IPv6      | None                  |
| 1d8990da-798b-43db-a022-3e80b06e3859 | tcp         | 0.0.0.0/0 | 22:22      | ingress   | IPv4      | None                  |
| cd7cd1ad-94b2-42ca-9aed-ee2e34b600be | tcp         | None      | 22:22      | ingress   | IPv6      | None                  |
| cda87185-428d-4e27-a9e4-a73faeb8068a | None        | None      |            | egress    | IPv4      | None                  |
+--------------------------------------+-------------+-----------+------------+-----------+-----------+-----------------------+
```

Now let's apply this group to `web01` and remove the default group from it:
```shell
$ openstack server add security group web01 allow-ssh
$ openstack server remove security group web01 default

# Check the changes are applied to the VM
$ openstack server show web01 -c security_groups
+-----------------+------------------+
| Field           | Value            |
+-----------------+------------------+
| security_groups | name='allow-ssh' |
+-----------------+------------------+
```

- :exclamation: **Task 1**: Test to connect to the VM via SSH and validate it works.

Try to ping the VM and realise it fails and you need to reevaluate your life choices.

- :exclamation: **Task 2**: Create a new group with rules allowing ping (protocol `icmp`) and add it
to `web01`. Test the ping again to validate.

## Allow HTTP
We now have a VM that is only reachable by SSH but not by HTTP and HTTPS. Check that it is indeed
the case:
```shell
$ curl http://XXX.XXX.XXX.XXX/
curl: (7) Failed to connect to XXX.XXX.XXX.XXX port 80: Connection timed out
```

Let's add a new group and rules for HTTP but limited to specific IPs:
```shell
$ openstack security group create --description 'Allow HTTP in' allow-http

# Find the public IP address of your machine
$ curl http://ifconfig.ovh/
YYY.YYY.YYY.YYY

# Add the rules for HTTP
$ openstack security group rule create \
    --description 'Allow restricted HTTP in' \
    --ingress \
    --ethertype IPv4 \
    --protocol tcp \
    --dst-port 80 \
    --remote-ip YYY.YYY.YYY.YYY \
    allow-http
```

- :exclamation: **Task 3**: Validate you can now connect to the VM's webserver over HTTP but not
HTTPS.

If you have access to another computer with a different IP (your workstation if you are using the
bounce container), try to connect via HTTP: it should not work.

# Allow HTTPS

You guessed it, we did not open HTTPS, so here are some tasks for you:
- :exclamation: **Task 4**: Add a security group and a rule for HTTPS from your machine.
- :exclamation: **Task 5**: Remove the `allow-http` from `web01` and replace it with the HTTPS group
created on the previous task. Validate that now only HTTPS works.
