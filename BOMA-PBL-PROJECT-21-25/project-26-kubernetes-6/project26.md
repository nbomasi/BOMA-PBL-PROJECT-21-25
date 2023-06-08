# Setting up private repositories and Preparing CI pipelines with Jenkins

In this project, we have quite a lot of exciting things to do. Lets get right into it.

As a follow up from previous project, the first thing you will need to do is create a repository in Artifactory which will serve as a private docker registry. Having a private registry in an enterprise means that there is more control over the containers deployed there. You have control over the secured traffic to the registry, control over storage and you can rely more on the availability of your images.

In Artifactory, you can setup either local, remote or virtual repositories. It doesn’t matter if it is for docker, helm, or standard software binaries.

Artifactory hosts two kinds of repositories: local and remote. Both local and remote repositories can be aggregated under virtual repositories, in order to create controlled domains for artifacts resolution and search, as we will see in the next sections.

### Local Repositories

Local repositories are physical locally-managed repositories that one can deploy artifacts into. Artifacts under a local repository are directly accessible via a URL pattern such as **https://tooling.artifactory.sandbox.svc.darey.io/artifactory/<local-repository-name>/<artifact-path>.**

### Remote Repositories

A remote repositories serves as a caching proxy for a repository managed at a remote URL (including other Artifactory remote repository URLs). Artifacts are stored and updated in remote repositories according to various configuration parameters that control the caching and proxying behavior. You can remove cached artifacts from remote repository caches but you cannot manually deploy anything into a remote repository.

Artifacts under a remote repository are directly accessible via a URL pattern of

**https://tooling.artifactory.sandbox.svc.darey.io/artifactory/<remote-repository-name>/<artifact-path>** or
**https://tooling.artifactory.sandbox.svc.darey.io/artifactory/<remote-repository-name>-cache/<artifact-path>**
The second URL will only serve already cached artifacts while the first one will fetch a remote artifact in the cache URL (2nd one) only if it is not already stored in the first URL.

### Virtual Repositories

A virtual repository (or “repository group”, if you prefer this term) aggregates several repositories under a common URL. The repository is virtual in the sense that you can resolve and get artifacts from it but you cannot deploy anything to it.

By default, Artifactory uses a global virtual repository that is available at **https://tooling.artifactory.sandbox.svc.darey.io/artifactory/repo** This repository contains all local and remote repositories.

### Lets create a local repository for docker.

* Click on administration, Repositoris , and **Add repositories as shown in the image below.


* Since we are exploring **Local Repositories**, select **Local Repository**


* Type **Docker** in the search box and select the **Docker** icon


* In the **Repository Key** box, type in the name of the repository you wh=ish to create. For example tooling. So that all the docker images for tooling app can be pushed there.


* Click on the **Create Local Repository** button.


* Now you can see that a **Docker Repository** for tooling has been created.


* Create a second **Local Repository for Jenkins**


**Lets create a Virtual Repository**

Remember, a virtual repository aggregates several repositories under a common URL. You can get artifacts from it but you cannot deploy anything to it.5

* Select **virtual Repository** 

* Name the **virtual Repository** as you deem fit, click on the **create Virtual Repository button**


* Now that the virtual repository is created, it is time to add local repositories to it. You can see in the image below that it is a **virtual** repo, and it will only be used by **Docker**.


* Scroll down the page to see the local repositories. This is where you select which local repository that will be part of the virtual repository. Click on the double arrows to move them.


* Once moved, you will see them in the included items section.




* To see the address of the virtual repository, simply click on the square icon at the top left, click on **Artifacts** and select the repository you wish to see more information on.


**Push docker images to the repository**
You can either pull and push docker images to the local repository for each application, or simply pull from the virtual repository.

Lets get docker images from docker hub and push to our private registry.

* First you will need to login to the docker registry.

```markdown
docker login tooling.artifactory.sandbox.svc.darey.io

```
* A successful login will create a file here **~/.docker/config.json** Explore this file and see how the authentication data is stored. The auth section is an encoding of your username and password. You can try to decode it with **base64** to see the output.

```markdown
{
        "auths": {
                "tooling.artifactory.sandbox.svc.darey.io": {
                        "auth": "YWRtaW46dGVzdF9wYXNzd29yZA=="
                }
        }
}
```

*Pull the Jenkins image from Docker hub

```markdown
docker pull jenkins/jenkins:jdk11
```

* Tag the image so that it can pushed to Artifactory. The image below shows how to get the repository URL address. 

```markdown
docker tag jenkins/jenkins:jdk11 https://tooling.artifactory.sandbox.svc.darey.io/jenkins/jenkins:jdk11
```

* Push the docker image to Artifactory

```markdown
docker push tooling.artifactory.sandbox.svc.darey.io/jenkins/jenkins:jdk11
```

## Jenkins pipeline for Business Applications

In earlier projects, pipeline for the Tooling app was based on Ansible. This time, we are containerising the same application. Since the app will be running inside a kubernetes cluster within a Pod container, then the approach to CI/CD will be different.

There will be different elements to CI/CD here. The build of the application, and the deployment into kubernetes.

1. The Dockerfile used to build the tooling app’s docker image will have its own CI/CD pipeline
2. The helm charts used to deploy the application into kubernetes will require its own CI/CD pipeline

Therefore, we will begin with the first one. But without jumping straight to creating pipelines, we must also consider the best way to automate the deployment and configuration of the CI/CD tool (**Jenkins)** such that it is fit for purpose, and can be easily recreated with the exact same config.

**Self Challenge Task:**

* Using helm, deploy Jenkins and sonarqube into the tools namespace.
* Configure TLS based ingress for both Jenkins and Sonarqube. (Use the Helm Values to configure Ingress directly)
* Create a Multibranch pipeline for the tooling app.
* Connect the tooling app from Github [https://github.com/darey-devops/tooling](https://github.com/darey-devops/tooling)
If you were able to successfully implement that challenge, then thumbs up to you.

Lets go through each of the steps.

**Deploy Jenkins with helm**

**Phase 1** – Deploy without any custom configuration to the Helm Values (Do the whole of this part yourself)

1. Without any custom configuration, get the Jenkins Helm chart from artifacthub.io, and deploy using the default values.
2. Configure DNS for jenkins and route traffic to the ingress controller load balancer
3. Deploy an ingress without TLS
4. Ensure that you are able to access the configured URL
5. Ensure that you are able to logon to Jenkiins.
6. Update the Ingress and configure TLS for the URL

**Phase 2**– Use an override values file to customize Jenkins deployment (You will be guided in this part)

The default helm values file has so many configuration tweaks to customize Jenkins. We will explore some of these and ensure that all desired configuration is done using the helm values only. For example, using another YAML file to configure the ingress is removed.

Tasks:

1. Configure Jenkins Ingress using Helm Values
2. Automate Jenkins plugin installation
3. Automating **Jenkins Configuration As Code (JCasC)**
4. Automating Jenkins backups to AWS S3
Lets get started (Note that the version numbers in provided screenshots or code snippets may have changed from the time of writing. Ensure to update the numbers as provided by the Helm chart)

1. Configure Jenkins Ingress using Helm Values
  * Delete the previous Ingress using **kubectl delete** command.
  * Create a new file and name it **jenkins-values-overide.yaml**
  * Find the below section in the default values file. Copy and paste it exactly in the **jenkins-values-overide.yaml**

```markdown
controller:
 # Used for label app.kubernetes.io/component
componentName: "jenkins-controller"
image: "jenkins/jenkins"
 # tag: "2.332.3-jdk11"
tagLabel: jdk11
imagePullPolicy: "Always"
```

* Then do a helm upgrade using the **jenkins-values-overide.yaml** file

 ```markdown
 helm upgrade -i jenkinsjenkinsci/jenkins-n tools -f jenkins-values-overide.yaml
 ```

* This should do an upgrade, but without any specific changes to the existing deployment. Thats because no configuration change has occured. All we now have is a shortened values file that can be easily read without too many options. With this file you can now start making configuration updates.

* To configure Jenkins ingress directly from the helm values, simply search for the ingress: section in the default values file and copy the entire section to the override values file.
The default one should look similar to this

```markdown
ingress:
enabled: false
   # Override for the default paths that map requests to the backend
paths: []
   # - backend:
   # serviceName: ssl-redirect
   # servicePort: use-annotation
   # - backend:
   # serviceName: >-
   # {{ template "jenkins.fullname" . }}
   # # Don't use string here, use only integer value!
   # servicePort: 8080
   # For Kubernetes v1.14+, use 'networking.k8s.io/v1beta1'
   # For Kubernetes v1.19+, use 'networking.k8s.io/v1'
apiVersion: "extensions/v1beta1"
labels: {}
annotations: {}
   # kubernetes.io/ingress.class: nginx
   # kubernetes.io/tls-acme: "true"
   # For Kubernetes >= 1.18 you should specify the ingress-controller via the field ingressClassName
   # See https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/#specifying-the-class-of-an-ingress
   # ingressClassName: nginx
   # Set this path to jenkinsUriPrefix above or use annotations to rewrite path
   # path: "/jenkins"
   # configures the hostname e.g. jenkins.example.com
hostName:
tls:
   # - secretName: jenkins.cluster.local
   # hosts:
   # - jenkins.cluster.local
```
* Given the ingress section copied above, attempt to update it with values for your specific ingress. Have a look through the ingress file you used to create the ingress previously and see what sections you require to update the values. For example
 * Enable the ingress value from false to true
 * Add the annotations you already used to create the ingress before
 * Add the hostname
 * Update the tls section with the secreName and hosts information.

* The final output should look similar to this

```markdown
ingress:
  enabled: true
  apiVersion: "extensions/v1beta1"
  annotations: 
    cert-manager.io/cluster-issuer: "letsencrypt-production"
    kubernetes.io/ingress.class: nginx
  hostName: tooling.jenkins.sandbox.svc.darey.io
  tls:
  - secretName: tooling.jenkins.sandbox.svc.darey.io
    hosts:
      - tooling.jenkins.sandbox.svc.darey.io
```

* Now upgrade the Jenkins deployment with **helm upgrade** command. Remember to specify the override yaml file with the -f file.

2. Automate Jenkins plugin installation

Jenkins rely heavily on plugins to extend its CI capabilities. As you know already, **Blueocean** is one of the widely used Jenkins plugin that gives much better experience. There are loads of other plugins that you may require to use as business requirements, and technical needs change.

Manually installing Jenkins plugins is definitely a bad idea. As a DevOps engineer, you want to be able to rely on your automated processes, thereby reducing manual configurations as much as possible.

There are 2 possible options to this.

1. You could use Helm values to automate plugin installation
2. You could package the required plugins as part of the Jenkins image.
Which ever option works just fine, Its a matter of choice and unique environment setup in an organisation.

**Option 1** is the easiest and most straight forward approach. But it may slow down initial deployment of Jenkins since it has to download the plugins. Also, if the kubernetes workers are completely closed from the internet. Hence, downloading plugins over the internet will not work, in this case Option 2 is the way out.

In the original values file, search for **installPlugins:** and you should see a section like below.

```markdown
  # List of plugins to be install during Jenkins controller start
  installPlugins:
    - kubernetes:3600.v144b_cd192ca_a_
    - workflow-aggregator:581.v0c46fa_697ffd
    - git:4.11.3
    - configuration-as-code:1429.v09b_044a_c93de

  # Set to false to download the minimum required version of all dependencies.
  installLatestPlugins: true

  # Set to true to download latest dependencies of any plugin that is requested to have the latest version.
  installLatestSpecifiedPlugins: false

  # List of plugins to install in addition to those listed in controller.installPlugins
  additionalPlugins: []
```

In the override yaml file, you can add the **installPlugins**: and **additionalPlugins:** so that your updated override values file will look like the below.

```markdown
controller:
  ingress:
    enabled: true
    apiVersion: "extensions/v1beta1"
    annotations: 
      cert-manager.io/cluster-issuer: "letsencrypt-production"
      kubernetes.io/ingress.class: nginx
    hostName: tooling.jenkins.sandbox.svc.darey.io
    tls:
    - secretName: tooling.jenkins.sandbox.svc.darey.io
      hosts:
        - tooling.jenkins.sandbox.svc.darey.io

  installPlugins:
    - kubernetes:3600.v144b_cd192ca_a_
    - workflow-aggregator:581.v0c46fa_697ffd
    - git:4.11.3
    - configuration-as-code:1429.v09b_044a_c93de

  additionalPlugins: []
```

If you need to include more plugins, you can use the additionalPlugins: [] key. the [] there simply means the key has a default **null** value and it is a **list** data type. Hence to start adding more plugins you simply need to update that section like below.

  ```markdown
  additionalPlugins:
    -blueocean:1.25.5    -credentials-binding:1.24    -git-changelog:3.0    -git-client:3.6.0    -git-server:1.9    -git:4.5.1
  ```

If you are wondering how to get the correct plugin version number, it is already provided on the same website where each plugin is documented at [https://plugins.jenkins.io](https://plugins.jenkins.io/)

Lets take the Blue Ocean plugin as an example. Navigate to [https://plugins.jenkins.io/blueocean/](https://plugins.jenkins.io/blueocean/) and see the Version section as shown below.



**Option 2** requires an extra overhead. Because you must create a Dockerfile for the Jenkins Controller or (Master), package the Jenkins docker image with the plugins already installed, then update the **image:** value in the helm values override file. The good thing about this approach, despite its overhead is that even when the Kubernetes cluster is locked down in a private network, the dependencies are already packaged into the image and there is no need to download anything from the internet.

Lets see what this process would look like.

*Create a folder structure and empty files like below

    ```markdown
     ├── Dockerfile
     └── scripts
         └── install-plugins.sh
    ```

*Update the Dockerfile with below content

```markdown
FROM jenkins/jenkins:2.354-jdk11

USER root

COPYscripts/ /opt/scripts/
RUNapt-get update && apt-get -y upgrade && \ chmod u+x /opt/scripts/install-plugins.sh && \ /opt/scripts/install-plugins.sh
USER jenkins
```

**Self Challenge Task:** Analyse the above Dockerfile and attempt to summarise each step.

* Update the install-plugins.sh file with below bash script.

  ```markdown
     #!/bin/bash

     # A variable to hold an array of all the plugins to be installed

     plugins=(
     workflow-basic-steps:948.v2c72a_091b_b_68
     blueocean:1.25.5
     credentials-binding:1.24
     git-changelog:3.0
     git-client:3.6.0
     git-server:1.9
     git:4.5.1
     )

     # A for loop to iterate over the plugins array, and execute the jenkins-plugin-cli command to instal each plugin.

     for plugin in "${plugins[@]}"
     do
       echo "Installing ${plugin}"
       jenkins-plugin-cli --plugins ${plugin}
     done
  ```

* Run docker commands to build, tag and push the docker image to the artifactory registry you created in previous project.
* Update the Jenkins helm values and point the new image to the private docker registry for Jenkins. Also, ensure that the values file have these keys set:
 ```markdown
 installPlugins: []
 additionalPlugins: []
 ```

Login to Jenkins and verify that the plugins have been installed.
Another way to verify the installation of the plugins is to** exec** into the **pod** container and check the filesystem. The command **ls -ltr /var/jenkins_home/plugins/ | grep blueocean** should return files relating to the plugin. If it returns empty, then the plugin has not been installed.

 ```markdown
 kubectl exec -it jenkins-0 -n tools -- bash

 echo $JENKINS_HOME
 /var/jenkins_home

 ls -ltr /var/jenkins_home/plugins/ | grep blueocean
 
 ```
1. Automating **Jenkins Configuration As Code** (JCasC)

Managing infrastructure “as code” is not only when you provision compute resources in the cloud or on-premise. Being able to reproduce and/or restore an entire environment within minutes extends beyond compute resourc eprovisioning, but also its configuration. There is so much configuration that can be done with Jenkins. Manually updating such configs from the user interface (UI) is not sustainable. Imagine creating a lot of folders to manage multiple projects and pipelines from the Jenkins UI and losing the Jenkins installation afterwards. You will have to manually recreate all the folders again. With Jenkins Configuration As Code (JCasC), this process can be automated and all configurations in Jenkins can now be represented as “code”

Ensure that all the installed plugins are using the latest version. Visit [https://plugins.jenkins.io/](https://plugins.jenkins.io/), then search for the plugin to get the latest version number.

To start managing Jenkins as code, search for JCasC: within the default yaml values file. That is the section where configuration as code needs to be configured.

Copy that section out of the default and put it in the override yaml file.

```markdown
JCasC:
defaultConfig: true
configScripts: {}
    # welcome-message: |
    # jenkins:
    # systemMessage: Welcome to our CI\CD server. This Jenkins is configured and managed 'as code'.
    # Ignored if securityRealm is defined in controller.JCasC.configScripts and
securityRealm: |-
local:
allowsSignup: false
enableCaptcha: false
users:
- id: "${chart-admin-username}"
name: "Jenkins Admin"
password: "${chart-admin-password}"
    # Ignored if authorizationStrategy is defined in controller.JCasC.configScripts
authorizationStrategy: |-
loggedInUsersCanDoAnything:
allowAnonymousRead: false
```

The **configScripts: {}** key shows that it is empty. The curly brackets {} indicates that it is configured to hold a dictionary type of data. This means that it can hold sub-keys with their own respective key and values. As you can see in the example below it.

    ```markdown
    configScripts: {}
    #  welcome-message: |
    #    jenkins:
    #      systemMessage: Welcome to our CI\CD server.  This Jenkins is configured and managed 'as code'.
    ```

To enable that section, simply remove the {} and uncomment the first key welcome-message. You can write whatever you want in the systemMessage. For example.

    ```markdown
    configScripts:
      welcome-message: |
        jenkins:
          systemMessage: Welcome to Darey.io Multi-tenant CI\CD server.  This Jenkins is configured and managed strictly 'as code'. 
    ```Please do not update Manually

Upgrade Jenkins with the latest update and you should see the system message like below.



The JCasC functionality is actually a Jenkins plugin. It is one of the most interesting plugins that makes configuring Jenkins very easy. It’s source code can be found here [https://github.com/jenkinsci/configuration-as-code-plugin](https://github.com/jenkinsci/configuration-as-code-plugin)

Without the **JCasC** plugin, setting up Jenkins is a complex process, as both Jenkins and its plugins require some tuning and configuration, with dozens of parameters to set within the web UI manage section.

Experienced Jenkins users rely on groovy init scripts to customize Jenkins and enforce the desired state. Those scripts directly invoke Jenkins API and, as such, can do everything (at your own risk). But they also require you to know Jenkins internals and are confident in writing groovy scripts on top of Jenkins API.

The Configuration as Code plugin is an opinionated way to configure Jenkins based on human-readable declarative configuration files. Writing such a file should be feasible without being a Jenkins expert.

To see some examples of the different configuration that can be done as code with Jenkins, navigate to the demo folder in the source code here [https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos](https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos)

Now let’s see the latest configuration applied to Jenkins through JCasC and Helm;

1. Navigate to Configuration as code section in Jenkins UI. Click on Configuration as Code


2. Click on View Configuration


3. You will see the updated code configuration here.

```markdown
![](./images/JCasC3.png)
```

Another example of automating Jenkins as code, is to create a multibranch pipline as part of Jenkins bootstrapping. Rather than going into the console to manually configure a pipeline.

Lets automate the creation of the tooling application’s pipeline.

First we need to create the credential to connect to the Github account where the tooling app is. If you have been following the PBL projects from Project 6, then you should already have the tooling app forked into your github account. If not, go ahead and fork it from here – [Tooling App](https://github.com/darey-devops/tooling)

Follow the below steps. NOTE: There is minimal guide on how to do the things listed below

1. Create an access token from GitHub so that Jenkins canm use it to connect to the Github account. **https://github.com/settings/tokens**

2. Using base64, encode the generated token

3. Create a secret in the same namespace where Jenkins is installed. Name the **key** **github_token** or whatever you wish. It doesn’t matter what it is called. But, take note of the name you use becuase it will be used elsewhere. See an example below. Replace the value with the encoded token you created earlier.

```markdown
apiVersion: v1
data:
github_token: Z2hwXzZQNThsUUNlfdjhfGakRLNDc1Q1FsS3BmZGU0Zk02ZjJDb1VCTA==
kind: Secret
metadata:
name: github
type: Opaque
```

In the Jenkins values file, you will set the values correctly so that the secret created above can be used. If you click [here](https://artifacthub.io/packages/helm/jenkinsci/jenkins?modal=values&path=controller.initScripts) to see the documentation in artifacthub.io, as shown in the image below.



Let’s analyse what is written there.

* **‘name’ is a name of an existing secret in same namespace as jenkins**. This refers to the secret created above. **github**
* **‘keyName’ is the name of one of the keys inside current secret**.. This refers to the key specified in the secret. **github_token**
* **the ‘name’ and ‘keyName’ are concatenated with a ‘-‘ in between, so for example:**. Therefore we will have this **github-github_token**

In the values file, we now need to update the key **additionalExistingSecrets:**

  ```markdown
  additionalExistingSecrets:
    - name: github
      keyName: github_token
  ```

**Note:** This is just to make Jenkins aware of the secret. We still need to use it in the credentials section so that Jenkins can connect to Github with it.

Then, create a folder to hold your pipelines

```markdown
  JCasC:
    enabled: true
    configScripts:
      welcome-message: |
        jenkins:
          systemMessage: Welcome to Darey.io Multi-tenant CI\CD server.  This Jenkins is configured and managed strictly 'as code'. Please do not update Manually
      pipeline: |
        jobs:
          - script: >
              folder('DAREY.IO') {
                displayName('DAREY.IO')
                description('Contains DAREY.IO Jenkins Pipelines')
              }
```

When you apply the latest changes, you should be able to see the folder created as shown below. But it doesn’t have any pipline.



Now, Lets create a pipline that will automatically be added to the folder upon installation.

The entire overide values file should look like this.

```markdown
controller:
image: "dareyregistry/jenkins"
tag: "2.357-jdk11.03"
ingress:
enabled: true
apiVersion: "extensions/v1beta1"
annotations: 
      cert-manager.io/cluster-issuer: "letsencrypt-production"
      kubernetes.io/ingress.class: nginx
hostName: tooling.jenkins.sandbox.svc.darey.io
tls:
- secretName: tooling.jenkins.sandbox.svc.darey.io
hosts:
- tooling.jenkins.sandbox.svc.darey.io
installPlugins: []

additionalExistingSecrets:
- name: github
keyName: github_token

JCasC:
enabled: true
configScripts:
welcome-message: |jenkins:
systemMessage: Welcome to Darey.io Multi-tenant CI\CD server.  This Jenkins is configured and managed strictly 'as code'. Please do not update Manually
pipeline: |jobs:
- script: > folder('DAREY.IO') { displayName('DAREY.IO') description('Contains DAREY.IO Jenkins Pipelines') }- script: > multibranchPipelineJob('DAREY.IO/tooling-app') { branchSources { git { remote('https://github.com/darey-devops/tooling.git') credentialsId('github') id('tooling-app') } } }security-config: |credentials:
system:
domainCredentials:
- credentials:
- usernamePassword:
id: github
username: darey-io
password: ${github-github_token}
scope: GLOBAL
description: Github
```

The most important part you must take note of is the credentials section where the secret we created earlier is used. Remember, the first part is the secret name github, while the second part is the “key name” used in the secret. github_token. Both are concatenated with an “hyphen”



The jenkins image used in the above values already has all the necessary plugins. Below is the exact **install-plugins.sh** script used for that image tag. You can use it for most use cases. But always remember to go to [https://plugins.jenkins.io/](https://plugins.jenkins.io/) to search for plugins and get the latest version.

```markdown
#!/bin/bash
plugins=(
workflow-basic-steps:948.v2c72a_091b_b_68
ace-editor:1.1
ansicolor:0.7.3
antisamy-markup-formatter:2.1
apache-httpcomponents-client-4-api:4.5.13-1.0
authentication-tokens:1.4
badge:1.8
bootstrap4-api:4.5.3-1
bouncycastle-api:2.18
branch-api:2.6.3
build-blocker-plugin:1.7.3
build-monitor-plugin:latest
blueocean:1.25.5
checks-api:1.2.0
cloudbees-folder:6.15
command-launcher:1.5
configuration-as-code:1464.vd8507b_82e41a_
config-file-provider:3.7.0
credentials-binding:523.vd859a_4b_122e6
credentials:1139.veb_9579fca_33b_
dashboard-view:2.14
dependency-check-jenkins-plugin:5.1.1
display-url-api:2.3.4
durable-task:1.35
echarts-api:4.9.0-2
email-ext:2.80
font-awesome-api:5.15.1-1
git-changelog:3.0
git-client:3.6.0
git-server:1.9
git:4.11.3
groovy-postbuild:2.5
handlebars:1.1.1
hashicorp-vault-plugin:3.7.0
htmlpublisher:1.25
jackson2-api:2.12.1
jacoco:3.1.0
jdk-tool:1.4
job-dsl:1.77
jquery-detached:1.2.1
jquery3-api:3.5.1-2
jsch:0.1.55.2
junit:1.48
kubernetes-client-api:5.12.2-193.v26a_6078f65a_9
kubernetes-credentials:0.9.0
kubernetes:3651.v908e7db_10d06
ldap:2.2
lockable-resources:2.10
mailer:1.32.1
mask-passwords:3.0
matrix-auth:2.6.4
matrix-project:1.18
metrics:4.0.2.6
momentjs:1.1.1
pipeline-build-step:2.13
pipeline-graph-analysis:1.10
pipeline-input-step:2.12
pipeline-milestone-step:1.3.1
pipeline-model-api:1.7.2
pipeline-model-definition:1.7.2
pipeline-model-extensions:1.7.2
pipeline-rest-api:2.19
pipeline-stage-step:2.5
pipeline-stage-tags-metadata:1.7.2
pipeline-stage-view:2.19
plain-credentials:1.7
plugin-util-api:1.6.1
popper-api:1.16.0-7
rebuild:1.31
role-strategy:3.1
scm-api:2.6.4
script-security:1.75
snakeyaml-api:1.27.0
soapui-pro-functional-testing:1.6
sonar:2.13
ssh-credentials:1.18.1
structs:1.20
token-macro:2.14
trilead-api:1.0.13
uno-choice:2.5.1
variant:1.4
workflow-aggregator:2.6
workflow-api:2.40
workflow-cps-global-lib:2.17
workflow-cps:2.87
workflow-durable-task-step:2.37
workflow-job:2.40
workflow-multibranch:2.22
workflow-scm-step:2.11
workflow-step-api:2.23
workflow-support:3.7
parameterized-scheduler:0.9.2
buildtriggerbadge:2.10
simple-theme-plugin:0.6
disk-usage:0.28
greenballs:1.15.1
text-finder:1.15
)

for plugin in "${plugins[@]}"
do
  echo "Installing ${plugin}"
  jenkins-plugin-cli --plugins ${plugin}
done
```

You can see the multiPipelineJob now created.



All the branches have automatically triggered their respective pipeliines.



This implementation is ideal, and gives the confidence of a re-usable code and infrastructure, should anything go wrong, you can easily recreate all you have configured.

You should also explore the JCasC section and see all the configured credentials and pipelines.



You can now create more secrets to connect to other tools, such as Sonarqube, AWS, KUBECONFIG etc…

Congratulations for completing Project 26.

Now, attempt to configure a remote artifactory repository.

1. Create a remote repository in Artifactory, so that instead of pulling helm charts directly from **https://charts.jenkins.io** for example, you will pulling directly from your configured remote repository in Artifactory. This helps organisations stay secure. Artifactroy will therefore be a proxy to pulling from the internet.

2. Configure remote repository for the following chart repos, search the repos and try to install tools from them through the Artifactroy remote repository you have configured.

```markdown
hashicorp               https://helm.releases.hashicorp.com
jenkins                 https://charts.jenkins.io
gitlab                  https://charts.gitlab.io
eks                     https://aws.github.io/eks-charts
jfrog                   https://charts.jfrog.io
prometheus-community    https://prometheus-community.github.io/helm-charts
kube-state-metrics      https://kubernetes.github.io/kube-state-metrics
grafana                 https://grafana.github.io/helm-charts
ingress-nginx           https://kubernetes.github.io/ingress-nginx
codecentric             https://codecentric.github.io/helm-charts
openstack-helm          https://registry.thecore.net.au/chartrepo/openstack
gabibbo97               https://gabibbo97.github.io/charts/
chartmuseum             https://chartmuseum.github.io/charts
kubernetes-dashboard    https://kubernetes.github.io/dashboard/
jenkinsci               https://charts.jenkins.io/
oauth2-proxy            https://oauth2-proxy.github.io/manifests
cert-manager            https://charts.jetstack.io
nginx                   https://helm.nginx.com/stable
sonarqube               https://SonarSource.github.io/helm-chart-sonarqube
istio                   https://istio-release.storage.googleapis.com/charts
```


In the next section we will leverage what we have done so far, and make some more sense of it all. You will gain hands-on experience;

1. Packaging the famous tooling app into a Helm chart
2. Publish the chart using Helm, and use Kustomize overlays to deploy into multiple environments
3. Optimize your deployment of existing applications (Arctifactory and Jenkins) through helm/kustomize
4. Introduce DevSecOps
5. Deploy Vault
6. Configure Vault and Kubernetes together
7. Automate dynamic secret injection for tooling app
8. Configure jenkins pipeline for Tooling app, moving from dev to production (RDS), and include a Quality Gate
