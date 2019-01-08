Through this workshop you will experiment with snaphosts of instances and volumes.

Snapshot are a copy of the instance disk or a volume at a certain point in time and provide the ability to restore an instance or a volume to this previous state.
Instance snapshot are also a way to create new images from which you can boot new instances.

This course assumes you have gone through the first two courses <sup>[1](../01_manage_resources_basic/01a_boot_instances.md), [2](../01_manage_resources_basic/01b_create_volumes.md)</sup>
and have in your project:
- at least one instance running Debian 9: it will be named`myvm01` in this workshop
- at least one volume, partitioned, formatted, attached and mounted on an instance: `volume01`

If you don't, make sure to create these resources before carrying on.

# Manage volume snapshots
## Create volume snapshots
First let's try to create a snapshot of one of the volumes:
```shell
openstack volume snapshot create --volume volume01 snapvol01-1
```

This will fail if the volume is attached so you have two choices:
- either unmount and detach the volume,
- or force the snapshot with the `--force` flag

We will choose to force it for this workshop:
```shell
$ openstack volume snapshot create --volume volume01 --force snapvol01-1
+-------------+--------------------------------------+
| Field       | Value                                |
+-------------+--------------------------------------+
| created_at  | 2019-01-08T20:34:08.342773           |
| description | None                                 |
| id          | 2302a554-4bda-4b28-b069-25167c7786c3 |
| name        | snapvol01-1                          |
| properties  |                                      |
| size        | 10                                   |
| status      | creating                             |
| updated_at  | None                                 |
| volume_id   | 47fcc836-3cc9-47ba-9d77-814fdc562167 |
+-------------+--------------------------------------+
```

> Be aware that this is a **very risky** operation for your data. In our case no processes are writing on this volume but in real life if you force a snapshot
> you will interrupt any application writing to the volume without notification so you might very well end up with a snapshot containing corrupted data; in other words
> a useless one.

You can check the status and progress of the snapshot with the command:
```shell
$ openstack volume snapshot show snapvol01-1
+--------------------------------------------+--------------------------------------+
| Field                                      | Value                                |
+--------------------------------------------+--------------------------------------+
| created_at                                 | 2019-01-08T20:34:08.000000           |
| description                                | None                                 |
| id                                         | 2302a554-4bda-4b28-b069-25167c7786c3 |
| name                                       | snapvol01-1                          |
| os-extended-snapshot-attributes:progress   | 100%                                 |
| os-extended-snapshot-attributes:project_id | fc55e5d2e09d426bab35580e0c237464     |
| properties                                 |                                      |
| size                                       | 10                                   |
| status                                     | available                            |
| updated_at                                 | 2019-01-08T20:34:09.000000           |
| volume_id                                  | 47fcc836-3cc9-47ba-9d77-814fdc562167 |
+--------------------------------------------+--------------------------------------+
```

> OpenStack Cinder (the component providing the volume functionality) makes a difference between volumes and snapshot so `openstack volume list` or `openstack volume show` will not
> display any information about the snapshots.

Let's write some new files on the volume to simulate new data on the volume:
```shell
# With the IP of the instance which has mounted volume01
$ ssh debian@XXX.XXX.XXX.XXX
debian@myvm01:~$ echo "$(date): new data added" | sudo tee /mnt/data.txt
debian@myvm01:~$ sudo wget -o /mnt/new.gif https://i.imgur.com/gthDCCw.gif
```

Now that we have new data on the volume, let's take another snapshot:
```shell
openstack volume snapshot create --volume volume01 --force snapvol01-2
```

Check that you now have 2 different snapshots with:
```shell
openstack volume snapshot list
```

## Restore volume snapshots
The way OpenStack allows you to restore the data from a snapshot is not a single revert operation. The steps you need to take are the following:
1. Create a new volume from a snapshot
2. Unmount and detach the volume from the server
3. Attach and mount the volume created from the snapshot

> You don't have to detach the old volume but if you need to revert it you probably don't need it anymore.

So let's create a new volume from the first snapshot:
```shell
openstack volume create --snapshot snapvol01-1 restoredvol01-1
```

Check the new volume's status has become `available` by using `openstack volume show restoredvol01-1` and then proceed to properly remove the volume:
```shell
# With the IP of the instance which has mounted volume01
$ ssh debian@XXX.XXX.XXX.XXX
debian@myvm01:~$ sudo umount /mnt
debian@myvm01:~$ logout
$ openstack server remove volume myvm01 volume01
$ openstack server show myvm01
[...]
# The row volumes_attached should be empty
```

And now plug in the restored volume:
```
$ openstack server add volume myvm01 restoredvol01-1
$ ssh debian@XXX.XXX.XXX.XXX

# Check the name of the device
debian@myvm01:~$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  20G  0 disk
└─sda1   8:1    0  20G  0 part /
sdb      8:16   0  10G  0 disk
└─sdb1   8:17   0  10G  0 part

debian@myvm01:~$ sudo mount /dev/sdb1 /mnt
debian@myvm01:~$ ls /mnt/
content.txt  lost+found
```

As you can see the new data has disappeared.

Now, some work for you:
- :exclamation: **Task 1**: Without detaching `restoredvol01-1`, create a volume from the second snapshot, attach and mount it on `myvm01` and ensure the new data is there.

# Manage instance snapshots
## Create instance snapshots
Snapshots of instances are named that way in OpenStack because what we commonly refer to a snapshot is nothing more than a new image. So creating a snapshot of an instance is
actually creating a new image based on this instance. Still the resulting image of the instance is a capture of the instance at a specific moment so the term "snapshot" is appropriate.

Before creating an image of `myvm01`, let's add a file in the user home directory to track if it appears when restoring it:
```shell
# With the IP of myvm01
$ ssh debian@XXX.XXX.XXX.XXX
debian@myvm01:~$ wget -o thisismyvm.gif https://i.imgur.com/GigziWv.gif
```

Create an image from `myvm01` and wait for it to be created (can take some time):
```shell
openstack server image create --name snapvm01-1 --wait myvm01
```

Using `openstack image list` the new image should show up amongst the public images. If you want to only see the image you created, use:
```shell
openstack image list --private
+--------------------------------------+------------+--------+
| ID                                   | Name       | Status |
+--------------------------------------+------------+--------+
| d24c1097-1006-41bd-a849-95026b20bd98 | snapvm01-1 | active |
+--------------------------------------+------------+--------+
```

## Restore instance snapshots
Now that our instance has been snapshot into an image, we can boot a copy of `myvm01` and wait for its completion with the following command:
```shell
openstack server create --image snapvm01-1 --flavor s1-4 --network Ext-Net --key-name mykey --wait restoredvm01
```

Once it is built, connect to it and verify the file left earlier is there:
```shell
# With the IP of restoredvm01
$ ssh debian@XXX.XXX.XXX.XXX
debian@restoredvm01:~$ ls
thisismyvm.gif
```

There is nothing more to do on snapshots so you can proceed to next [workshop](02b_stop_pause_delete_instances.md).
