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

Reading instance metadata.
Find associated device.
Checking if /dev/sdb is formatted...
Formatting /dev/sdb to ext4.
Checking if /dev/sdb is mounted...
Mounting /dev/sdb to /data.
Done!
```

Example integration with Longhorn
---------------------------------

Since this tooling is executed as initContainers, this can be easily integrated in applications using hostPath mounts by:

- adding the necessary secret
- inserting the initContainers (with `hostPID:` true for mountvol)
- adding the host volume to /tmp to push the mount script.

You can find such an integration in the folder `example`

```
$ diff longhorn-addvol.yaml longhorn-orig.yaml
4792,4805d4791
< ---
< apiVersion: v1
< kind: Secret
< metadata:
<   name: config-addvol
<   namespace: longhorn-system
< stringData:
<   SCW_ACCESS_KEY: SCWxxxx
<   SCW_DEFAULT_ORGANIZATION_ID: xxxx-xx-xxxxx-xxxxx
<   SCW_SECRET_KEY: xxxx-xx-xxxxx-xxxxx
<   SCW_DEFAULT_PROJECT_ID: xxxx-xx-xxxxx-xxxxx
<   VOL_SIZE: "500G"
<   PREFIX: "longhorn"
<   IOPS: "15000"
4830,4852d4815
<       hostPID: true
<       initContainers:
<       - name: addvol
<         image: ghcr.io/n-arno/kapsule-host-vol-addvol:latest
<         imagePullPolicy: Always
<         envFrom:
<         - secretRef:
<             name: config-addvol
<       - name: mountvol
<         image: ghcr.io/n-arno/kapsule-host-vol-mountvol:latest
<         imagePullPolicy: Always
<         securityContext:
<           privileged: true
<         volumeMounts:
<         - name: k8s-node
<           mountPath: /k8s-node
<         env:
<         - name: FOLDER
<           value: /var/lib/longhorn
<         command:
<         - /bin/sh
<         - -c
<         - cp /mount.sh /k8s-node/mount.sh && /usr/bin/nsenter -m/proc/1/ns/mnt -- /tmp/scripts/mount.sh "$FOLDER"
4924,4926d4886
<       - name: k8s-node
<         hostPath:
<           path: /tmp/scripts
```

Warning
-------

This will create a volume with the instance ID in its name. It does not handle deleting this volume if the instance is deleted, this could lead to several orphan volumes.


