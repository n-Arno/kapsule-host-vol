kapsule-host-vol
================

Fire and forget method to add a block volume directly to the host.

Check `addvol-combined.yaml` for an example on how to add a volume and mount it to a specific folder

V2
--

This version is a complete rework. Now adding the volume and mounting it are combined as a single container, with more accurate and reliable tests.

Previous packages (addvol/mountvol) are kept to avoid breaking previous deployments but must not be used => **they don't handle nodes having multiple volumes connected**


usage
-----

Edit corresponding file to add your Scaleway API key to access instances and block storage volume requested, together with the target mount folder on the nodes.

Apply to the cluster

```
kubectl apply -f add-and-mount.yaml
```

Example logs:

```
Executing with values: VOL_SIZE=10G PREFIX=addvol IOPS=5000
Checking if metadata magic link is reachable, exit otherwise.
Reading instance metadata.
Searching for volume ID.
Volume is not created, doing so...
Volume is not attached.
Attaching volume...
Starting the mount script in PID 1 namespace
Executing with values: VOLUME_ID=c6abc3b7-d6e1-4e7f-94d5-bd6e627dc7c0 FOLDER=/data
Checking if metadata magic link is reachable, exit otherwise.
Sleep for a second to ensure metadata are up to date
Checking instance metadata for VOLUME_ID, exit if not found
Finding associated device.
Checking if /dev/sdc is formatted...
Formatting /dev/sdc to ext4.
Checking if /dev/sdc is mounted...
Mounting /dev/sdc to /data.
Mount done!
All done!
```

Example integration with Longhorn
---------------------------------

Since this tooling is executed as initContainers, this can be easily integrated in applications using hostPath mounts by:

- adding the necessary secret
- inserting the initContainers (with `hostPID: true`)
- mounting to /k8s-node the host volume /tmp/scripts to push the mount script.

You can find such an integration in the folder `example`, together with the original file.

```
$ diff longhorn-addvol.yaml longhorn-orig.yaml
4793,4807d4792
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
<   VOL_SIZE: "100G"
<   PREFIX: "longhorn"
<   IOPS: "15000"
<   FOLDER: "/var/lib/longhorn"
< ---
4831,4843d4815
<       hostPID: true
<       initContainers:
<       - name: add-and-mount-vol
<         image: ghcr.io/n-arno/kapsule-host-vol-combined:latest
<         imagePullPolicy: Always
<         securityContext:
<           privileged: true
<         volumeMounts:
<         - name: k8s-node
<           mountPath: /k8s-node
<         envFrom:
<         - secretRef:
<             name: config-addvol
4915,4917d4886
<       - name: k8s-node
<         hostPath:
<           path: /tmp/scripts
```


Warning
-------

This will create a volume with the instance ID in its name. It does not handle deleting this volume if the instance is deleted, this could lead to several orphan volumes.


