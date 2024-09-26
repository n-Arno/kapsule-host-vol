kapsule-host-vol
================

Fire and forget method to add a block volume directly to the host.

- `addvol-only.yaml` only add the volume and nothing else
- `add-and-mount.yaml` add the volume and mount it to a specific folder

usage
-----

Edit corresponding file to add your Scaleway API key to access instances and block storage volume.

Apply to the cluster

```
kubectl apply -f addvol-only.yaml

-or-

kubectl apply -f add-and-mount.yaml
```

Example logs:

```
$ kubectl logs addvol-c7p5v -n kube-system -c addvol

Executing with values: VOL_SIZE=20G PREFIX=addvol IOPS=15000
Checking if metadata magic link is reachable, exit otherwise.
Reading instance metadata.
Searching for volume ID.
No volume found attached.
Volume is not created, doing so...
Attaching volume...
Done!

$ kubectl logs addvol-c7p5v -n kube-system -c mountvol

Checking if /dev/sdb is formatted...
Formatting /dev/sdb to ext4.
Checking if /dev/sdb is mounted...
Mounting /dev/sdb to /data.
Done!
```


Warning
-------

This will create a volume with the instance ID in its name. It does not handle deleting this volume if the instance is deleted, this could lead to several orphan volumes.

