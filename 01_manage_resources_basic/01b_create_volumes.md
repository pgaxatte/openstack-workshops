This workshop will guide you through the creation and attachment of volumes.

Volumes can be seen as an external hard drive for your instances: they are virtual disks that you can attach to your instances to extend their storage capacity.

Pre-requisites: you need to have completed the [first course](01a_boot_instances.md) and have booted **two** instances.

# Create a volume
The creation of a volume is very simple, just issue the following command to create a 10GB volume:
```shell
openstack volume create --size 10 volume01
```

This will output some information about the newly created volume:
```
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| attachments         | []                                   |
| availability_zone   | nova                                 |
| bootable            | false                                |
| consistencygroup_id | None                                 |
| created_at          | 2019-01-03T14:07:04.298131           |
| description         | None                                 |
| encrypted           | False                                |
| id                  | 42c791f9-a84a-4034-b7cd-a1048054c50b |
| multiattach         | False                                |
| name                | volume01                             |
| properties          |                                      |
| replication_status  | disabled                             |
| size                | 10                                   |
| snapshot_id         | None                                 |
| source_volid        | None                                 |
| status              | creating                             |
| type                | classic                              |
| updated_at          | None                                 |
| user_id             | 12843a2...                           |
+---------------------+--------------------------------------+
```

Notice that the `attachments` list is empty so this volume is currently not attached just as an unplugged external hard drive.
In this state it is not very useful.

You can run the following command to get back this information at a later time:
```shell
openstack volume show volume01

# Or with its id:
openstack volume show 42c791f9-a84a-4034-b7cd-a1048054c50b
```

# Using the volume
## Attach the volume to an instance
To be able to manipulate the volume you need to attach it to an instance.
There is no need to shut down the instance prior the attachment so we will attach the volume on a live instance:
```shell
openstack server add volume myvm01 volume01
```

You can check that the attachment is effective by looking at the instance or at the volume:
```shell
openstack server show myvm01
# -> the ID of the volume is displayed in the volumes_attached property

openstack volume show volume01
# -> the attachments list now contains information about which instance it is attached to and the device that is used on the instance (/dev/sdb most likely)
```

## Format and mount the volume
Connect to the instance you attached the volume to:
```shell
# With the ip of myvm01
ssh debian@XXX.XXX.XXX.XXX
```

You can check the disks connected to the instance:
```shell
debian@myvm01:~$ lsblk
```
You should see a second disk on the instance:
```
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  20G  0 disk
└─sda1   8:1    0  20G  0 part /
sdb      8:16   0  10G  0 disk
```

The new disk (`/dev/sdb` here) is blank and does not have a partition nor a filesystem on it.
So let's create one:
```shell
debian@myvm01:~$ echo 'start=2048, type=83' | sudo sfdisk /dev/sdb
```

This created a single partition starting at the offset 2048 and with a type 83 meaning `Linux`.
Another run of `lsblk` should confirm there is now a partition on the volume:
```
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  20G  0 disk
└─sda1   8:1    0  20G  0 part /
sdb      8:16   0  10G  0 disk
└─sdb1   8:17   0  10G  0 part
```

Now we need to format it:
```shell
debian@myvm01:~$ sudo mkfs.ext4 /dev/sdb1
```

Finally we can mount it and use it:
```shell
debian@myvm01:~$ sudo mount /dev/sdb1 /mnt
```

And check the 10GB are there with `df -h` for instance:
```
Filesystem      Size  Used Avail Use% Mounted on
udev            1.9G     0  1.9G   0% /dev
tmpfs           386M   39M  348M  11% /run
/dev/sda1        20G 1016M   18G   6% /
tmpfs           1.9G     0  1.9G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           1.9G     0  1.9G   0% /sys/fs/cgroup
/dev/sdb1       9.8G   37M  9.3G   1% /mnt
```

Now we add some data on the volume:
```shell
debian@myvm01:~$ echo "This is volume01" | sudo tee /mnt/content.txt
```

## Move the volume to another instance
One of the benefits of a volume is that you can detach it and reattach it to another instance so let's do that.

But first **you have to** unmount the volume on `myvm01`:
```shell
debian@myvm01:~$ sudo umount /mnt
```

Now we can *safely* detach the volume:
```shell
openstack server remove volume myvm01 volume01
```

And reattach it to the other instance:
```shell
openstack server add volume myvm02 volume01
```

Now let's connect to `myvm02`:
```shell
# With the ip of myvm02
ssh debian@XXX.XXX.XXX.XXX
```

> Tip: you can see the IP of the instance with `openstack server show myvm02`

And check everything is there:
```shell
debian@myvm02:~$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  20G  0 disk
└─sda1   8:1    0  20G  0 part /
sdb      8:16   0  10G  0 disk
└─sdb1   8:17   0  10G  0 part
debian@myvm02:~$ sudo mount /dev/sdb1 /mnt
debian@myvm02:~$ cat /mnt/content.txt
This is volume01
```

# You're up
Now you should be able to do the following tasks on your own:
- :exclamation: **Task 1**: Detach `volume01` from `myvm02` and reattach it to `myvm01`
- :exclamation: **Task 2**: Create a second volume: `volume02`
- :exclamation: **Task 3**: Attach `volume02` to `myvm02` then partition it and format it
- :exclamation: **Task 4**: Mount `volume02` and add some content to it

Once you are ready, move on to the [next course](01c_create_private_network_and_ports.md)
