# Deploy and Manage Business Application in Kubernetes – Helm | Kustomize | GitOps

Based on your experience on previous projects, you already have a grasp of **Helm** by now. But you should also know that there are multiple choices available when it comes to deploying applications into kubernetes. So, Helm should not always be your default choice. It is important to be aware of the options available, know the pros and cons, and choose what works for your team or project.

Lets quickly discuss the different options, and make an informed decision before starting the actual work.

1. **Write YAML files and deploy with kubectl** – This is the easiest method where you write YAML for deployments, services, ingress, and all of that, and then deploy with **kubectl apply -f <YAML-FILE>**. This is usually the default way when getting started with kubernetes. OR during development and exploration. But it is not sufficient or reliable when it comes to managing the infrastructure in production. It is hard work to keep track of multiple yaml files. You can imagine what will be the fate of your project if there are tens or hundreds of microservices/applications that needs to be managed across multiple environments. With this type of approach, you will end up in a [PEBKAC Situation](https://www.google.com/search?q=PEBKAC+situation&rlz=1C5CHFA_enGB766GB766&oq=PEBKAC+situation&aqs=chrome..69i57j33i160.1849j0j7&sourceid=chrome&ie=UTF-8)
2. **Use a templating engine like HELM** – You already know about Helm. Its value propositions to install applications, manage the lifecycle of those applications across multiple environments, and customise applications through templating. Without going deeper into its obvious benefits, it also has its downsides too. for example;
 1. Helm only adds value when you install community components. Tools you can easily find on **artifacthub.io** Otherwise you need to write yaml anyway.
 2. Leads to too much logic in the templates (This is not good for inexperienced kubernetes users, and a problem to hiring managers)
 3. Learning another DevOps tool. Always be careful about introducing yet another tool into your team/project. Similar to number 3 above, it slows down the project.
 4. Everyone’s Kubernetes cluster is different. Your needs are different. You might need to make a change to the way the chart is deployed – like changing a small piece of configuration in the templates folder. But, like a remote control, you’ve only got a limited set of controls which are exposed to you (the values that are exposed in the values.yaml file). If you want to make any deeper changes to the Helm chart, you’ll need to fork it and change it yourself. (This is a bit like taking a remote control apart, and adding a new button!)
3. **Kustomize Overlays** – To overcome the challenges of Helm identified above, using a tool that is already embeded as part of kubectl; which you are already familiar with makes more sense for most use cases. You will get to see how Kustomize works shortly. For now, understand that another option is to use Overlays, instead of a templating engine. The downside to this is that it does not manage the lifecycle of your aplications like Helm is able to do. Therefore, you will need to use other methods alongside Kustomize for this.

Before we make a final decision on how we will realistically manage deployments into Kubernetes, lets see how Kustomize works.

## How Kustomize Works

Kustomize uses a file called kustomization.yaml that contains declarative specifications to what resources need to be imported from what manifest files and what changes need to be made. Once it has processed the resources, it emits them to the standard output, which can be stored in a file or directly used with kubectl to apply it to a particular cluster.

One of the excellent use cases of Kustomize is to manage Kubernetes resources for multiple environments. For Kustomize to work in that scenario, you would need a base directory that would contain all manifest files with all the common elements and an overlays directory that contains all the differences for a particular environment.

To understand better, let’s look at a hands-on example.

### Installing Kustomize

Kustomize comes pre bundled with kubectl version >= 1.14. You can check your version using kubectl version. If version is 1.14 or greater there’s no need to take any steps.

For a stand alone Kustomize installation(aka Kustomize cli), go through the official documentation to install [Kustomize – Here](https://kubectl.docs.kubernetes.io/installation/kustomize/)

### Working with Kustomize

kustomize is a command line tool supporting template-free, structured customization of declarative configuration targeted to k8s-style objects.

Targeted to k8s means that kustomize has some understanding of API resources, k8s concepts like names, labels, namespaces, etc. and the semantics of resource patching.

kustomize is an implementation of [Declarative Application Management (DAM)](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#declarative-application-management). A set of best practices around managing k8s clusters.

It is a configuration management solution that leverages layering to preserve the base settings of your applications and components by overlaying declarative yaml artifacts (called patches) that selectively override default settings without actually changing the original files.

Kustomize relies on the following system of configuration management layering to achieve reusability:

* Base Layer – Specifies the most common resources
* Patch Layers – Specifies use case specific resources

Let’s step through how Kustomize works using a deployment scenario involving 3 different environments: **dev**, **sit**, and **prod**. In this example we’ll use service, deployment, and namespace resources. For the dev environment, there wont be any specific changes as it will use the same configuration from the base setting. In sit and prod environments, the replica settings will be different.

Using the tooling app for this example, create a folder structure as below.

```markdown
└── tooling-app-kustomize
    ├── base
    │   ├── deployment.yaml
    │   ├── kustomization.yaml
    │   └── service.yaml
    └── overlays
        ├── dev
        │   ├── kustomization.yaml
        │   └── namespace.yaml
        ├── prod
        │   ├── deployment.yaml
        │   ├── kustomization.yaml
        │   └── namespace.yaml
        └── sit
            ├── deployment.yaml
            ├── kustomization.yaml
            └── namespace.yaml
```
Now, lets walk through the content of each file.

### Base directory

**tooling-app-kustomize/base/deployment.yaml** – This is a standard kubernetes yaml file for a deployment.

```markdown
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tooling-deployment
  labels:
    app: tooling
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tooling
  template:
    metadata:
      labels:
        app: tooling
    spec:
      containers:
      - name: tooling
        image: dareyregistry/tooling-app:1.0.2
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

**tooling-app-kustomize/base/service.yaml** – This is a standard kubernetes yaml file for a service.

```markdown
apiVersion: v1
kind: Service
metadata:
  name: tooling-service
  labels:
    app: tooling
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
    name: http
  type: ClusterIP
  selector:
    app: tooling
```
**tooling-app-kustomize/base/kustomization.yaml**– This is a Kustomization declaritive yaml that is used to let kustomize know what resources to create and monitor in kubernetes.

```markdown
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
```

The resources being monitored here are deployment and services. You can simply add more to the list as you wish.

It is assumed that we will need to deploy kubernetes resources across multiple environments, as a standard practice in most cases. Hence, to deploy resources into the Dev environment, lets see what the layout and file contents will look like.

## DEV Environment

In the **overlays** folder – This is where you manage multiple environments. In each environment, there is a Kustomize file that tells Kustomize where to find the base setting, and how to **patch** the environment using the **base** as the starting point.

In the **dev** environment for example, the namespace for dev is created, and the deployment is patched to use a replica count of **“3”** different from the base setting of **“1”**. So Kustomize will simply create all the resources in base, in addition to whatever is specified in the dev directory. We will discuss patching a little further in the following section.

Lets have a look at what each file contains.

**tooling-app-kustomize/overlays/dev/namespace.yaml**

```markdown
apiVersion: v1
kind: Namespace
metadata:
  name: dev-tooling
```

**tooling-app-kustomize/overlays/dev/deployment.yaml**

```markdown
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tooling-deployment
spec:
  replicas: 3
```

**tooling-app-kustomize/overlays/dev/kustomization.yaml**

```markdown
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: dev
bases:
- ../../base

commonLabels:
  env: dev-tooling

resources:
  - namespace.yaml
```

The Kustomization file for dev here specifies that the base configuration should be applied, and include the yaml file(s) specified in the resources section. It also indicates what namespace the configuration should be applied to.

In summary it specifies the following;

* The apiversion
* The Kind of resource (kustomization)
* The namespace where this kustomizaton will create or patch resources
* The location of the base folder, where the base configuration can be found.
* The resource(s) to be created – Such as a namespace or deployment
* A **commonLabel** field which ensures that kubernetes labels and selectors are automatically injected into the resources being created. such as below;

Generally, A kustomization file contains fields falling into four categories (although not all have been used in the example above):

**resources** – what existing resources are to be customized. Example fields: resources, crds.

**generators** – what new resources should be created. Example fields: configMapGenerator (legacy), secretGenerator (legacy), generators (v2.1).

**transformers** – what to do to the aforementioned resources. Example fields: namePrefix, nameSuffix, images, commonLabels, etc. and the more general transformers (v2.1) field.

**meta** – fields which may influence all or some of the above. Example fields: vars, namespace, apiVersion, kind, etc.

### Patching configuration with Kustomize

With Kustomize, you can now begin to patch your environments with extra configurations that overwrites the base setting either by

creating new resources, or
patching existing resources.
This is all achieved through the **overlays** configuration. The **overlays/
dev/kustomization.yaml**
example above only creates a new resource. What if we wanted to patch an existing resource. For example increase the pod replica from the default 1 to 3 as shown in the **overlays/dev/deployment.yaml** file

It would look like;

```markdown
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: dev-tooling
bases:
- ../../base

commonLabels:
  env: dev-tooling

resources:
  - namespace.yaml

patches:
  - deployment.yaml
```

Now lets apply the configuration and see what happens.

```markdown
kubectl apply -k overlays/dev
```
Notice that the the apply flag here is -k rather than the -f we have been using all along. This is because kubectl has been made aware of Kustomize. You can use kustomize cli directly, but since you are already familiar with kubectl, it just makes sensee to use the kustomize flag that comes bundled with kubectl.

Output will look like this;

```markdown
namespace/dev-tooling created
service/tooling-service created
deployment.apps/tooling-deployment created
```

**Self Side Task:**

With your understanding of how kustomize is able to patch resources per environment, now configure both **SIT** and **PROD** environments with their respective overlays and set different configuration values for

* pod replica
* resource limit and requests

### Helm Template Engine vs. Kustomize Overlays

Both technologies have good reasons why they are designed the way they are. But most of the experienced engineers in the industry would rather get the best of both worlds.

With helm, you can simply install already packaged applications from [artifacthub.io](https://www.artifacthub.io/), and then use kustomize to patch its values files.

For business applications, you can choose to package your applications in helm and simply patch the values files with kustomize as well. But you might also just use helm only for applications you wish to download from the public, and use kustomize directly for business applications.

### Integrate the tooling app with Amazon Aurora for Dev, SIT, and PROD environments

1. Configure Terraform to deploy an aurora instance
2. Use the tooling.sql script to load the database schema
3. Configure environment variables for database connectivity in the deployment file and patch the each environment for the appropriate values

### Integrate Vault with Kubernetes

Before we integrate Vault with our Kubernetes cluster, we will have will be using Helm and Kustomize to for the installation. The [vault helm chart](https://artifacthub.io/packages/helm/hashicorp/vault) is the recommended way to install vault in a kubernetes cluster and configure it. In this project we will configure Vault to use [High Availability Mode](https://www.vaultproject.io/docs/concepts/ha) with **Integrated storage (Raft)**, This is recommended for production-ready deployment. This installs a StatefulSet of Vault server Pods with either Integrated Storage, or a Consul storage backend. The Vault Helm chart, however, can also configure Vault to run in standalone mode, or [dev](https://www.vaultproject.io/docs/concepts/dev-server).

Create the folder structure as below:

```markdown
vault
├── base
│   ├── kustomization.yaml
│   └── namespace.yaml
└── overlays
    ├── dev
    │   ├── .env
    │   ├── kustomization.yaml
    │   ├── namespace.yaml
    │   └── values.yaml
    ├── sit
    │   ├── .env
    │   ├── kustomization.yaml
    │   ├── namespace.yaml
    │   └── values.yaml
    └── prod
        ├── .env
        ├── kustomization.yaml
        ├── namespace.yaml
        └── values.yaml
```
Now let’s work through the content of each file.

**vault/base/namespace.yaml/** – This is a standard kubernetes yaml file for a namespace.

```markdown
apiVersion: v1
kind: Namespace
metadata:
  name: vault
```

**vault/base/kustomization.yaml**

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - "namespace.yaml"

**Dev Environment**

**vault/overlays/dev/namespace.yaml**

```markdown
apiVersion: v1
kind: Namespace
metadata:
  name: vault
  labels:
    env: vault=dev
```

**vault/overlays/dev/kustomization.yaml**

```markdown
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# this will over write the namespace all the resourses will be deployed to
namespace: vault

resources:
  - ../../base

patchesStrategicMerge:
  - namespace.yaml

# list the helm chart we want to 
helmCharts:
  - name: vault
    namespace: vault
    repo: https://helm.releases.hashicorp.com
    releaseName: vault
    version: 0.22.0
    valuesFile: values.yaml

secretGenerator:
  - name: vault-kms
    env: .env

generatorOptions:
  disableNameSuffixHash: true
```

Break down of the Kustomization declaritive yaml field above:

* namespace – Namespace to add to all objects. This will overwrite the .metadata.namespace of the resources that will be created.
* resources – Each entry in resources list must be a path to a file, or a path (or URL) referring to another kustomization directory.
* patchesStrategicMerge – The names in these resource files must match names already loaded via the resources field. These entries are used to modify the known resources.
* helmCharts – Each entry in the argument list results in the pulling and rendering of a helm chart. This can have the following fields:
 * name: The name of the chart that you want to use.
 * repo: [Optional] The URL of the repository which contains the chart. If this is provided, the generator will try to fetch remote charts. Otherwise it will try to load local chart in chartHome.
 * chartHome: [Optional] Provide the path to the parent directory for local chart.
 * version: [Optional] Version of the chart. Will use latest version if this is omitted.
 * releaseName: [Optional] The release name that will be set in the chart.
 * namespace: [Optional] The namespace which will be used by –namespace flag in helm template command.
 * valuesFile: [Optional] A path to the values file.
 * valuesInline: holds value mappings specified directly, rather than in a separate file.
 * valuesMerge: specifies how to treat valuesInline with respect to Values. Legal values: ‘merge’, ‘override’, ‘replace’. Defaults to ‘override’.
 * includeCRDs: specifies if Helm should also generate CustomResourceDefinitions. Defaults to ‘false’.
 * configHome: [Optional] The value that kustomize should pass to helm via HELM_CONFIG_HOME environment variable. If omitted, {tmpDir}/helm is used, where {tmpDir} is some temporary.

**vault/overlays/sit/.env** – The dotenv file is used to pass the Vault KMS key into the vault configuration, which you will see later.

```markdown
VAULT_SEAL_TYPE=awskms
VAULT_AWSKMS_SEAL_KEY_ID=<arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab>
```

**vault/overlays/dev/values.yaml** – Most of the configuration for the Vault installation will be done in this values file. Before we start adding add the values file, create a folder (“terraform”) in the root directory of your workspace which you will use to create **AWS Key Management Service (KMS)** key and **IAM roles** for service accounts. Your folder structure will look like this:

```markdown
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── providers.tf
└── vault/
    ├── base/
    │   ├── kustomization.yaml
    │   └── namespace.yaml
    └── overlays/
        ├── dev/
        │   ├── .env
        │   ├── kustomization.yaml
        │   ├── namespace.yaml
        │   └── values.yaml
        ├── sit/
        │   ├── .env
        │   ├── kustomization.yaml
        │   ├── namespace.yaml
        │   └── values.yaml
        └── prod/
            ├── .env
            ├── kustomization.yaml
            ├── namespace.yaml
            └── values.yaml
```

We will be creating the **AWS KMS** key because when a Vault server is started, it starts in a sealed state and it does not know how to decrypt data. Before any operation can be performed on the Vault, it must be unsealed. Unsealing is the process by which the Vault root key is used to decrypt the data encryption key that Vault uses to encrypt all data.

**IAM roles for service accounts** provide the ability to manage AWS credentials for the vault, similar to the way that Amazon EC2 instance profiles provide credentials to Amazon EC2 instances. Instead of using the Amazon EC2 instance’s role or creating and distributing your AWS credentials to the vault containers through the Helm values file, we simply associate an IAM role with a Kubernetes service account and configure the pods to use the service account.

Update the terraform files

**terraform/providers.tf**

```markdown
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.34.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}
```

**terraform/main.tf**


```markdown
module "vault_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.2.0"
  role_name   = "vaultKMS"
  create_role = true
  role_policy_arns = {
    AWSKeyManagementServicePowerUser = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
  }

  oidc_providers = {
    one = {
      provider_arn               = module.eks.dev_eks_oidc_provider_arn #data.aws_eks_cluster.dev-eks.identity[0].oidc[0].issuer
      namespace_service_accounts = ["vault:vault-kms", ]
    }
  }
  attach_custom_iam_policy = false

  tags = var.tags
}

module "vault_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "1.0.2"
  description             = "Complete key example showing various configurations available"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = false

  # Policy
  enable_default_policy = true
  key_owners            = [data.aws_iam_role.vault_kms.arn]
  key_administrators    = [data.aws_iam_role.vault_kms.arn]
  key_users             = [data.aws_iam_role.vault_kms.arn]

  # Aliases
  aliases                 = ["dev-vault-kms"]
  aliases_use_name_prefix = true

  # Grants
  grants = {}

  tags = var.tags
}


# This data source can be used to fetch information about vault IAM role.
data "aws_iam_role" "vault_kms" {
  name = "vaultKMS"
  depends_on = [
    module.vault_iam_role
  ]
}
```

```markdown
terraform/variables.tf
```

```markdown
variable "tags" = {
  type    = map
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

On your terminal, change directory to the terraform and initializes the terraform directory containing Terraform files.

```markdown
cd terraform
terraform init
```

Run the command terraform plan to preview the changes that Terraform plans to make to your infrastructure, then terraform apply to executes the actions proposed in the plan.

```markdown
terraform plan -out tfplan

terraform apply tfplan
```

Before we add the content of the values file, we need to install Ingress Controller and Cert-Manager. If you don’t have those tools installed in your cluster, you can reference [project 25](../project-25-kubernetes-5) for this.

* Ingress Controller: For this [ingress controller](https://kubernetes.github.io/ingress-nginx/deploy/) you can use the Nginx ingress controller helm chart for the installation. You can deploy the ingress controller with the following command:

```markdown
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --create-namespace --namespace ingress-nginx
```

This will install the controller in the ingress-nginx namespace, creating that namespace if it doesn’t already exist.

* Cert-Manager: This a Kubernetes addon to automate the management and issuance of TLS certificates from various issuing sources. It will ensure certificates are valid and up to date periodically, and attempt to renew certificates at an appropriate time before expiry. Visit the [project 25](../project-25-kubernetes-5) documentation for the installation.

After the installation of cert-manager and the ingress controller the next step is to configure the vault installation from the values file then deploy it.

**vault/overlays/dev/values.yaml**

```markdown
server:
  enabled: "-"
  image:
    repository: "hashicorp/vault"
    tag: "1.11.3"
    # Overrides the default Image Pull Policy
    pullPolicy: IfNotPresent

  # Configure the Update Strategy Type for the StatefulSet
  updateStrategyType: "OnDelete"

  # Ingress allows ingress services to be created to allow external access
  # from Kubernetes to access Vault pods.
  ingress:
    enabled: true
    labels: {}
    annotations: 
      cert-manager.io/cluster-issuer: letsencrypt-prod
      cert-manager.io/private-key-rotation-policy: Always      

    ingressClassName: "nginx"
    pathType: Prefix

    activeService: true
    hosts:
      - host: "vault.masterclass.dev.darey.io"
        paths: [/]
    tls:
     - secretName: vault.masterclass.dev.darey.io
       hosts:
         - vault.masterclass.dev.darey.io

  terminationGracePeriodSeconds: 10

  # extraSecretEnvironmentVars is a list of extra environment variables to set with the stateful set.
  # These variables take value from existing Secret objects.
  extraSecretEnvironmentVars:
    - envName: VAULT_SEAL_TYPE
      secretName: vault-kms
      secretKey: VAULT_SEAL_TYPE
    - envName: VAULT_AWSKMS_SEAL_KEY_ID
      secretName: vault-kms
      secretKey: VAULT_AWSKMS_SEAL_KEY_ID

  # Enables a headless service to be used by the Vault Statefulset
  service:
    enabled: true

    # Port on which Vault server is listening
    port: 8200
    # Target port to which the service should be mapped to
    targetPort: 8200
    # Extra annotations for the service definition.
    annotations: {}

  # This configures the Vault Statefulset to create a PVC for data
  # storage when using the file or raft backend storage engines.
  dataStorage:
    enabled: true
    # Size of the PVC created
    size: 2Gi
    # Location where the PVC will be mounted.
    mountPath: "/vault/data"
    # Name of the storage class to use.  If null it will use the
    # configured default Storage Class.
    storageClass: null
    # Access Mode of the storage device being used for the PVC
    accessMode: ReadWriteOnce
    annotations: {}

  # Run Vault in "HA" mode. There are no storage requirements unless the audit log
  # persistence is required.  In HA mode Vault will configure itself to use Consul
  # for its storage backend.
  ha:
    enabled: true
    replicas: 3

    # Set the api_addr configuration for Vault HA
    # See https://www.vaultproject.io/docs/configuration#api_addr
    # If set to null, this will be set to the Pod IP Address
    apiAddr: null

    # Set the cluster_addr confuguration for Vault HA
    # See https://www.vaultproject.io/docs/configuration#cluster_addr
    # If set to null, this will be set to https://$(HOSTNAME).{{ template "vault.fullname" . }}-internal:8201
    clusterAddr: null

    # Enables Vault's integrated Raft storage.  Unlike the typical HA modes where
    # Vault's persistence is external (such as Consul), enabling Raft mode will create
    # persistent volumes for Vault to store data according to the configuration under server.dataStorage.
    # The Vault cluster will coordinate leader elections and failovers internally.
    raft:

      # Enables Raft integrated storage
      enabled: true
      # Set the Node Raft ID to the name of the pod
      setNodeId: true

      config: |
        ui = true

        listener "tcp" {
          tls_disable = 1
          address = "[::]:8200"
          cluster_address = "[::]:8201"
        }

        storage "raft" {
          path = "/vault/data"

          retry_join {
            leader_api_addr = "http://vault-0.vault-internal:8200"
          }

          retry_join {
            leader_api_addr = "http://vault-1.vault-internal:8200"
          } 

          retry_join {
            leader_api_addr = "http://vault-2.vault-internal:8200"
          }

          autopilot {
            cleanup_dead_servers = "true"
            last_contact_threshold = "200ms"
            last_contact_failure_threshold = "10m"
            max_trailing_logs = 250000
            min_quorum = 5
            server_stabilization_time = "10s"
          }
        }

        # cluster_addr = "http://vault:8200"

        service_registration "kubernetes" {}


    # config is a raw string of default configuration when using a Stateful
    # deployment. Default is to use a Consul for its HA storage backend.
    # This should be HCL.
    config: |
      ui = true

      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }

      seal "awskms" {
      }

      service_registration "kubernetes" {}

      log_requests_level = "trace"

  # Definition of the serviceAccount used to run Vault.
  # These options are also used when using an external Vault server to validate
  # Kubernetes tokens.
  serviceAccount:
    # Specifies whether a service account should be created
    create: true
    # The name of the service account to use.
    # If not set and create is true, a name is generated using the fullname template
    name: "vault-kms"
    # Extra annotations for the serviceAccount definition. This can either be
    # YAML or a YAML-formatted multi-line templated string map of the
    # annotations to apply to the serviceAccount.
    annotations: 
      eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/vaultKMS ## Update role for new AWS account


# Vault UI
ui:
  # True if you want to create a Service entry for the Vault UI.
  #
  # serviceType can be used to control the type of service created. For
  # example, setting this to "LoadBalancer" will create an external load
  # balancer to access the UI.
  enabled: true
  publishNotReadyAddresses: true
  # The service should only contain selectors for active Vault pod
  activeVaultPodOnly: false
  serviceType: "ClusterIP"
  serviceNodePort: null
  externalPort: 8200
  targetPort: 8200
```

**Install Vault**: Update the ServiceAccount annotations with jsonpath=”{server.serviceAccount.annotations}” with your account ID. Change directory to the vault directory and run the command below to install vault in your cluster. Replace the “vault.masterclass.dev.darey.io” with your domain name and update the record on your hosted zone.

From the values file above we are using **ingress** under the **server** field to configure the ingress. The ingress is configured with TLS certificate, and the certificate is managed by **Cert-manager** which is configured with the ingress annotation as you can see below.

```markdown
ingress:
  annotations: 
    cert-manager.io/cluster-issuer: letsencrypt-prod
    cert-manager.io/private-key-rotation-policy: Always
```

Apply the changes to your cluster

```markdown
kubectl apply -k overlays/dev
```
Follow the next steps to initialize the Vault cluster.

* Run the command below to execute commands in one of the pod with running status **kubectl exec -n vault -it <running_vault_pod_name> -- /bin/sh** vault-running-pod pod/vault-0 is the pod in running status in this image
* Check the status the vault cluster vault status, you should get an output similar to this:--- ----- Recovery Seal Type awskms Initialized false Sealed true Total Recovery Shares 0 Threshold 0 Unseal Progress 0/0 Unseal Nonce n/a Version 1.11.3 Storage Type raft HA Enabled true
* To initialize the Vault cluster you will run:vault operator init You should get something similar to this after initializing the Vault cluster: Recovery Key 1: iz1XWx...C+MA6Rc Recovery Key 2: rKZETr...+bjeUT7 Recovery Key 3: 4XA/KJ...dlUjRFv Recovery Key 4: lfnaYo...AfKkUmd Recovery Key 5: L169hH...kGWdUtW Initial Root Token: hvs.UWnDag...L72wysn Success! Vault is initialized Recovery key initialized with 5 key shares and a key threshold of 3. Please securely distribute the key shares printed above. Copy the output into a file and save it.
* Check the status after when the vault cluster is unseal vault status:Key Value --- ----- Recovery Seal Type shamir Initialized true Sealed false Total Recovery Shares 5 Threshold 3 Version 1.11.3 Build Date 2022-08-26T10:27:10Z Storage Type raft Cluster Name vault-cluster-741dfb4f Cluster ID d1879609-c784-9647-12a6-72cc65ecf37a HA Enabled true HA Cluster https://vault-1.vault-internal:8201 HA Mode active Active Since 2022-10-21T01:47:06.989163982Z Raft Committed Index 10252 Raft Applied Index 10252 From the vault status output before you initialize the Vault cluster will see that the seal type is awskms, but after initializing the vault cluster you will get the recovery keys (instead of **unseal keys**) because some of the Vault operations still require **shamir keys**. The Recovery keys generated after running vault operator init can be used to unseal the cluster when it is sealed manually or to regenerate a root token.The **awskms** key type is used for **auto unseal**, using the awskms key type you don’t have to manually unseal the pod if it gets recreated. Move to the next page to see how you can inject secrets from the Vault cluster into an application.

## Dynamically inject secrets into the tooling app container

In this session we will see how we can securely inject the tooling application database credentials from the vault cluster into the tooling application. This method can be used to pass secrets credentials like password, token and other secrets credential into an application without the application being aware of the vault cluster.

To store the secrets we need to create a Vault secret of type **KV Version 2**, this is a versioned Key-Value store. You can exit out of the vault pod and install Vault on your local machine from [here](https://developer.hashicorp.com/vault/downloads) if you don’t have vault installed on your system. Export the vault address and login.

```markdown
export VAULT_ADDR="https://vault.masterclass.dev.darey.io"

vault login
```
Copy and paste the root token after the vault login command.

Enable the kv-v2 secrets at the path **app**.

```markdown
vault secrets enable -path=app kv-v2
```

Create the tooling application database credentials at the path **app/database/config/dev**.

```markdown
vault kv put app/database/config/dev username=db password=password host=http://database
```

Verify that the secret is defined at the path **app/database/config/dev**.

```markdown
vault kv get app/database/config/dev

```
## Configure Kubernetes Authentication

Enable the kubernetes auth method at the default path.

```markdown
vault auth enable kubernetes
```
Configure Vault to talk to Kubernetes with the /config path. This will require the Kubernetes host address, use **kubectl cluster-info** to get the Kubernetes host address and TCP port replace it with the **kubernetes_host** from the command below.

```markdown
vault write auth/kubernetes/config \
  kubernetes_host=https://DJEII84983J3UU3J3UE3JKE93IE93.yu3.eu-west-3.eks.amazonaws.com
```
You will get something like this: **auth/kubernetes/config**

```markdown
Success! Data written to: auth/kubernetes/config
```
In order for the tooling application to read the database credentials it needs the read capability to the path **app/data/database/config**, we can do this by creating a policy and attach it to Kubernetes authentication role we will create.

```markdown
vault policy write tooling-db - <<EOF
path "app/data/database/config/*" {
  capabilities = ["read"]
}
EOF
```

Create a kubernetes authentication role named tooling-role

```markdown
vault write auth/kubernetes/role/tooling-role \
  ttl=6h \
  policies=tooling-db \
  bound_service_account_names=tooling-sa \
  bound_service_account_namespaces=dev
```

You should get something like this:

```markdown
Success! Data written to: auth/kubernetes/role/tooling-role
```

### Inject Secrets into the Tooling Application

In order to inject secrets into the tooling application you will create a service-account with the name configured in the kubernetes role and attach it to the tooling application pod. This will create a sidecar which is the Vault agent and it will do the authentication and inject the secrets into the application.

In the **tooling-app-kustomize/overlays**

directory where you have your Kubernetes manifest files, create a file **service-account.yaml** and add:

```markdown
tooling-app-kustomize/overlays/dev/service-account.yaml
```


```markdown
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tooling-sa
```

In the **tooling-app-kustomize/overlays/dev/deployment.yaml**
file, replace the content with:

```markdown
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tooling-deployment
spec:
  replicas: 3
  template:
    metadata:
      annotation:
        vault.hashicorp.com/agent-inject: 'true'
        vault.hashicorp.com/role: 'tooling-role'
        vault.hashicorp.com/agent-inject-status: 'update'
        vault.hashicorp.com/agent-inject-secret-database-cred.txt: 'app/data/database/config/dev'
        vault.hashicorp.com/agent-inject-template-database-cred.txt: |
          {{- with secret "app/data/database/config/dev" -}}
          export db-username={{ .Data.data.username }}
          export db-password={{ .Data.data.password }}
          export db-host={{ .Data.data.password }}
          {{- end -}}
    spec:
      serviceAccountName: tooling-sa
```

Add the **service-account.yaml** file under the resources field of your Kustomization file in the dev directory. The Kustomization file should look like this:

```markdown
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: dev
resources:
  - ../../base
  - namespace.yaml
  - service-account.yaml

commonLabels:
  env: dev-tooling

patches:
  - deployment.yaml
```

Now lets apply the configuration.

```markdown
kubectl apply -k overlays/dev
```
You can inspect the tooling application pod, you will find out that the new pod now launches two containers. The application container, named tooling, and the Vault Agent container, named vault-agent.

Vault Agent manages the token lifecycle and the secret retrieval. The database credentials will be saved at the path /**vault/secrets/database-cred.txt** in the tooling application container. Run the command below to check the content of the file.

```markdown
kubectl exec -it deployment/tooling-deployment \
  -c tooling -- cat /vault/secrets/database-cred.txt
```

To export the Database credentials in the tooling application you can run the command below:

```markdown
kubectl exec -it deployment/tooling-deployment \
  -c tooling -- source /vault/secrets/database-cred.txt
```
**Working with the Vault UI**

We have been using the vault cli for our vault configurations but you can also use the vault UI to do some of the configurations. To view the vault UI, copy and paste the vault address on your browser, then you will see the login page.

vault-login-page
You can login using the token you got after initializing the vault cluster. Check the database KV secret created before which is at the path app/database/config/dev.

### Working with the Vault UI

We have been using the vault cli for our vault configurations but you can also use the vault UI to do some of the configurations. To view the vault UI, copy and paste the vault address on your browser, then you will see the login page.

vault-login-page
You can login using the token you got after initializing the vault cluster. Check the database KV secret created before which is at the path **app/database/config/dev**.

vault-secrets
database-kv-secret
Check the tooling-role kubernetes auth method role.

vault-auth-methods
vault-kubernetes-auth
Navigate to the vault policy attached to the tooling-role kubernetes auth method.

vault-policy