# PERSISTING DATA IN KUBERNETES

I created the EKS Cluster using the following k8s manifest 

This project take us through how we can keep our pod data save even if our pods dies and anther is created, both configuration files and data are kept saf for the newly created pod/s. To archieve this the follow methods will be used:

* **Persistent Volume (PV) and Persistent Volume Claim (PVC)**
* **CONFIGMAP**

The process is detailed in [project23.md file](project23.md)