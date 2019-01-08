This workshop's goal is to manipulate some disruptive functions that will control the execution of
instances.

This course assumes you have completed the first course<sup>[1](../01_manage_resources_basic/01a_boot_instances.md)</sup>
and have at least one instance running Debian 9 in you project; it will be named`myvm01` in this
workshop.

# Start and stop instances
The `start` and `stop` are the simplest and most explicit commands there is.

You can use them as follows:
```shell
openstack server stop myvm01
```

This will properly and gracefully shutdown the instance.
You can check the status of the VM with `openstack server show myvm01` and it should show `SHUTOFF`.

You boot the machine again with the following command:
```shell
openstack server start myvm01
```

The status should get back to `ACTIVE` quickly.

> On the cloud provider standpoint, stopped instances are still consuming resources on the
> hypervisor (because they still occupy disk space) so usually they are billed as if they were
> running. Therefore stopping is generally used for maintenance operations is not meant to be long
> term states (although nothing prevents it).

# Reboot an instance
There is two ways to reboot an instance: either soft or hard.

The soft reboot will try to gracefully restart the instance whereas the hard reboot will instruct
the hypervisor to shut it down without notice.

Gracefully reboot `myvm01` and wait for it to come back up:
```shell
openstack server reboot --soft --wait myvm01
```

This should take less than a minute.
In case the `--soft` command does not return, you can interrupt it with `CTRL-c` and retry the
reboot with `--hard`

> Hard reboot are useful when an operation on the VM has resulted in an error. The need for a hard
> reboot occurs generally when the hypervisor failed and not when the VM is in a bad state of
> execution.
>
> The hard reboot will instruct the hypervisor to recreate the context of the VM (its XML definition
> in libvirt to be precise) before rebooting it allowing the recovery from most errors.

`openstack server show myvm01` should now report an `ACTIVE` status and you can check the uptime
of the vm using:
```
# With the IP of myvm01
$ ssh debian@XXX.XXX.XXX.XXX "uptime"
 10:12:49 up 0 min,  0 users,  load average: 0.00, 0.00, 0.00
```

# Pause/unpause and suspend/resume
OpenStack offers multiple possibilities to interrupt an instance and resume it at a later point
while keeping the current state of execution:
- `pause` will interrupt the execution and store the state of the VM in the RAM of the hypervisor
very much like a suspend to RAM on any computer; the executionis resumed via the `unpause`
subcommand.
- `suspend` will also interrupt the VM but stores the state on disk instead. This is like an
hibernation on a computer. The execution is resumed via `resume`.

> As for a stopped instance, paused and suspended instances are also consuming "live" resources on
> the hypervisor so usually they are also billed as if they were running.
>
> Pausing is well adapted to safely snapshot the volumes attached (you will still have to use
> `--force`) or speeding up the snapshot of an instance with an intensive CPU/RAM workload.

## Pause/unpause an instance
To pause an instance, use this command:
```shell
openstack server pause myvm01
```

You can check that the status of the instance is now `PAUSED` and you should not be able to ping it
anymore:
```shell
# With the IP of myvm01
$ ping -W 1 -v XXX.XXX.XXX.XXX
PING XXX.XXX.XXX.XXX (XXX.XXX.XXX.XXX) 56(84) bytes of data.
From 192.168.250.1 icmp_seq=1 Destination Host Unreachable
From 192.168.250.1 icmp_seq=2 Destination Host Unreachable
From 192.168.250.1 icmp_seq=3 Destination Host Unreachable
From 192.168.250.1 icmp_seq=4 Destination Host Unreachable
[...]
```

Now unpause it and try to ping it again:
```shell
$ openstack server unpause myvm01
$ ping -W 1 -v XXX.XXX.XXX.XXX
PING XXX.XXX.XXX.XXX (XXX.XXX.XXX.XXX) 56(84) bytes of data.
64 bytes from XXX.XXX.XXX.XXX: icmp_seq=1 ttl=50 time=11.3 ms
64 bytes from XXX.XXX.XXX.XXX: icmp_seq=2 ttl=50 time=11.3 ms
64 bytes from XXX.XXX.XXX.XXX: icmp_seq=3 ttl=50 time=11.4 ms
64 bytes from XXX.XXX.XXX.XXX: icmp_seq=4 ttl=50 time=11.3 ms
```

It should very quickly resume its execution and connectivity.

## Resume/suspend an instance
This is your turn to do it:
- :exclamation: **Task 1**: Using the `suspend` subcommand, interrupt `myvm01`'s execution and check
the status of the instance.
- :exclamation: **Task 2**: Using the `resume` subcommand, resume `myvm01`'s execution. Did you
notice a longer delay before getting back the ping?

> When using flavors with a lot of RAM, the suspend and resume actions can be significantly slower
> because it will take more time to dump the memory on the disk and read it back.

# Shelve and unshelve instances
Shelving an instance is a function that extends the `stop` command by taking a snapshot and putting
it away to completely unload the hypervisor of the VM's context. While restarting an instance will
boot it on the same hypervisor, unshelving will potentially choose an other hypervisor to redeploy
the instance and start it.

> The main benefit of this is that (usually) a shelved instance is not billed anymore, only the
> storage of the snapshot will still be billed which makes it more suitable for long term
> interruption.

## Shelve an instance
Let's try it and see where this leads:
```shell
openstack server shelve myvm01
```

Check the status of the VM and you might see this intermediate state:
```shell
$ openstack server show myvm01
+-----------------------------+----------------------------------------------------------+
| Field                       | Value                                                    |
+-----------------------------+----------------------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                                   |
| OS-EXT-AZ:availability_zone | nova                                                     |
| OS-EXT-STS:power_state      | Shutdown                                                 |
| OS-EXT-STS:task_state       | shelving_image_uploading                                 |
| OS-EXT-STS:vm_state         | stopped                                                  |
| OS-SRV-USG:launched_at      | 2019-01-08T19:26:24.000000                               |
| OS-SRV-USG:terminated_at    | None                                                     |
| accessIPv4                  |                                                          |
| accessIPv6                  |                                                          |
| addresses                   | Ext-Net=xxx:yyy::zzz, XXX.XXX.XXX.XXX                    |
| config_drive                |                                                          |
| created                     | 2019-01-08T19:25:53Z                                     |
| flavor                      | s1-4 (3c83dfbd-abdb-43d0-b041-3ac44009c2f7)              |
| hostId                      | e9eb14ad1509dc15d5b53b8007076170623ae1a2f8188e5b770c73b4 |
| id                          | a9419969-bae7-448d-979f-a52a37500193                     |
| image                       | Debian 9 (d60f629d-7f22-4db8-9f4a-cf480a26856f)          |
| key_name                    | mykey                                                    |
| name                        | myvm01                                                   |
| project_id                  | fc55e5...                                                |
| properties                  |                                                          |
| security_groups             | name='default'                                           |
| status                      | SHUTOFF                                                  |
| updated                     | 2019-01-09T19:20:35Z                                     |
| user_id                     | 5c274ea71eaf436c8e6ba1af140d1f5d                         |
| volumes_attached            | id='084e0895-dc0b-4677-a542-f17b20b2b402'                |
+-----------------------------+----------------------------------------------------------+
```

> Notice the `OS-EXT-STS:task_state` field is `shelving_image_uploading` while the snapshot is being
> moved outside of the hypervisor

Once the shelving is done, the status will be updated to `SHELVED_OFFLOADED`.

A new image has also been created automatically named `myvm01-shelved` to store the snapshot of the
instance.

Let's take a closer look:
```shell
$ openstack image show --max-width=100 myvm01-shelved
+------------------+-------------------------------------------------------------------------------+
| Field            | Value                                                                         |
+------------------+-------------------------------------------------------------------------------+
| checksum         | d78b334e67e9f3a370f8dcadcec80faf                                              |
| container_format | bare                                                                          |
| created_at       | 2019-01-09T19:20:32Z                                                          |
| disk_format      | qcow2                                                                         |
| file             | /v2/images/e8ae67b0-363a-4c04-b40a-254358ae6665/file                          |
| id               | e8ae67b0-363a-4c04-b40a-254358ae6665                                          |
| min_disk         | 20                                                                            |
| min_ram          | 0                                                                             |
| name             | myvm01-shelved                                                                |
| owner            | fc55e5...                                                                     |
| properties       | base_image_ref='d60f629d-7f22-4db8-9f4a-cf480a26856f',                        |
|                  | build_id='e969709d-6136-4e99-bb87-22051eb3dee6',                              |
|                  | data='/home/glance/images/Debian-9.raw',                                      |
|                  | direct_url='swift+config://ref1/glance/e8ae67b0-363a-4c04-b40a-254358ae6665', |
|                  | hw_disk_bus='scsi', hw_scsi_model='virtio-scsi', image_build_date='2018-11-11 |
|                  | 11:46:35', image_location='snapshot', image_original_user='debian',           |
|                  | image_state='available', image_type='snapshot', instance_uuid='a9419969-bae7  |
|                  | -448d-979f-a52a37500193', locations='[{u'url':                                |
|                  | u'swift+config://ref1/glance/e8ae67b0-363a-4c04-b40a-254358ae6665',           |
|                  | u'metadata': {}}]', owner_id='fc55e5...',                                     |
|                  | user_id='5c274e...'                                                           |
| protected        | False                                                                         |
| schema           | /v2/schemas/image                                                             |
| size             | 1430061056                                                                    |
| status           | active                                                                        |
| tags             |                                                                               |
| updated_at       | 2019-01-09T19:21:02Z                                                          |
| virtual_size     | None                                                                          |
| visibility       | private                                                                       |
+------------------+-------------------------------------------------------------------------------+
```

As it is shown on the output, the shelved instance's snapshot has been immediately moved out of the
hypervisor to be stored on [swift](https://docs.openstack.org/swift/latest/), the component managing
OpenStack's object storage.

This cryptic information is hidden in the properties:
`direct_url='swift+config://ref1/glance/e8ae67b0-363a-4c04-b40a-254358ae6665'`

## Unshelve an instance
We can now unshelve the instance and get it back up:
```shell
openstack server unshelve myvm01
```

While the instance is being brought back, the status will stay `SHELVED_OFFLOADED` and the
`OS-EXT-STS:task_state` will be `spawning`. Once this is completed the instance's status will change
to `ACTIVE` and we can connect to it again.

- :exclamation: **Task 3**: Shelve and unshelve again an instance but this time pay attention to the
`hostId` field before and after unshelving. Did it change?

# Resizing an instance
Sometimes you need to upgrade (or downgrade) the flavor of an instance without having to redeploy
everything on it. For this purpose it is possible to resize the instance's "shell".

The resize is not done live, a new VM is discretely created with the new flavor, the data from
the source VM is copied on it and when the target VM has booted, the source is destroyed.

Be aware that there are restrictions in the flavors you can resize to. The main requirement is that
the target flavor has a disk size greater or equal than the starting flavor.

This is the reason the `*-flex` exist so for this exercise we will first create a new VM with a
`b2-7-flex` flavor:
```shell
openstack server create \
    --image 'Debian 9' \
    --flavor b2-7-flex \
    --key-name mykey \
    --network Ext-Net \
    --wait \
    resizeme
```

Once it is up, you can upgrade it to a `b2-15-flex` flavor:
```shell
$ openstack server resize --flavor b2-15-flex --wait resizeme
Complete
$ openstack server show resizeme
+-----------------------------+----------------------------------------------------------+
| Field                       | Value                                                    |
+-----------------------------+----------------------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                                   |
| OS-EXT-AZ:availability_zone | nova                                                     |
| OS-EXT-STS:power_state      | Running                                                  |
| OS-EXT-STS:task_state       | None                                                     |
| OS-EXT-STS:vm_state         | active                                                   |
| OS-SRV-USG:launched_at      | 2019-01-09T21:16:35.000000                               |
| OS-SRV-USG:terminated_at    | None                                                     |
| accessIPv4                  |                                                          |
| accessIPv6                  |                                                          |
| addresses                   | Ext-Net=xxx:yyy::zzz, XXX.XXX.XXX.XXX                    |
| config_drive                |                                                          |
| created                     | 2019-01-09T21:08:59Z                                     |
| flavor                      | b2-15-flex (61979bc1-f22a-4f6e-9cca-7300841ea820)        |
| hostId                      | 5e936bfe4275113363c26f13e0557948008b0d0cb0ad3a68a4fda4d8 |
| id                          | 865badf8-b744-4929-a13e-d65f629d5e70                     |
| image                       | Debian 9 (d60f629d-7f22-4db8-9f4a-cf480a26856f)          |
| key_name                    | mykey                                                    |
| name                        | resizeme                                                 |
| progress                    | 0                                                        |
| project_id                  | fc55e5...                                                |
| properties                  |                                                          |
| security_groups             | name='default'                                           |
| status                      | ACTIVE                                                   |
| updated                     | 2019-01-09T21:16:59Z                                     |
| user_id                     | 5c274ea...                                               |
| volumes_attached            |                                                          |
+-----------------------------+----------------------------------------------------------+
```

> This operation can take some time because the content of the disk is copied possibly to a
> different hypervisor. So the larger the disk, the longer the wait.

If you encounter an `ERROR` state, `reboot --hard` is your friend as it will force the hypervisor
to recreate the VM's context to what it originally was. Be patient and check the
`OS-EXT-STS:task_state` which should indicate `reboot_started_hard` when the VM is actually being
rebooted. Then try again.

Once the resize has succeeded, your VM should have gone from an `b2-7-flex` to an `b2-15-flex`
flavor. Here are their specs:
```shell
# Unleash some awk witchcraft
$ openstack flavor list -c Name -c RAM -c VCPUs -c Disk --sort-column RAM \
    | awk 'NR < 4 || $2~/^b2-[0-9]+-flex/ { print } END { print }'
+-----------------+--------+------+-------+
| Name            |    RAM | Disk | VCPUs |
+-----------------+--------+------+-------+
| b2-7-flex       |   7000 |   50 |     2 |
| b2-15-flex      |  15000 |   50 |     4 |
| b2-30-flex      |  30000 |   50 |     8 |
| b2-60-flex      |  60000 |   50 |    16 |
| b2-120-flex     | 120000 |   50 |    32 |
+-----------------+--------+------+-------+
```

You can log into the VM to see if it now has ~15GB of RAM and 4 CPUs:
```shell
# With the IP of resizeme
$ ssh debian@XXX.XXX.XXX.XXX
debian@resizeme:~$ grep '^MemTotal' /proc/meminfo
MemTotal:       15040000 kB
debian@resizeme:~$ grep -c '^processor' /proc/cpuinfo
4
```

As you can see the new specs are applied!

- :exclamation: **Task 4**: Downgrade `resizeme` back to a `b2-7-flex` and check the specs are
applied.

# Rebuild and delete instances
Finally let's use the two commands that actually destroy data. Up until now, the commands shown
would only stop or interrupt the execution but data stored on the VM's disk is never lost.

Rebuilding an instance means recreating it and its disk completely anew while keeping the same
properties. And deleting means, well, permanently deleting it and its disk.

Your tasks will be:
- :exclamation: **Task 5**: Find the right command to rebuild and delete an instance with
`openstack server --help`
- :exclamation: **Task 6**: Remove all the instances from your project except one.
- :exclamation: **Task 7**: Rebuild the last instance standing. What is the benefit of rebuilding an
instance instead of deleting and re-creating it?

:crown: Keep calm and carry on to the workshop on the [security groups and rules](02c_security_groups.md).
