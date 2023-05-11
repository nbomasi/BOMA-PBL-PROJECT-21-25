# DEPLOYING AND PACKAGING APPLICATIONS INTO KUBERNETES WITH HELM

In the previous project, you started experiencing helm as a tool used to deploy an application into Kubernetes. You probably also tried installing more tools apart from Jenkins.

In this project, we will experience deploying more DevOps tools, get familiar with some of the real world issues faced during such deployments and how to fix them. You will learn how to tweak helm values files to automate the configuration of the applications you deploy. Finally, once you have most of the DevOps tools deployed, you will experience using them and relate with the DevOps cycle and how they fit into the entire ecosystem.

**Our focus will be on the following tools.**

1. Artifactory
2. Hashicorp Vault
3. Prometheus
4. Grafana
5. Elasticsearch ELK using [ECK](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-install-helm.html)

But in this project we will focus on artifactory,  intall and use inginx ingress controller and finally how to secure our external assess to our Kubernetes sevice using SSL/TLS protocol