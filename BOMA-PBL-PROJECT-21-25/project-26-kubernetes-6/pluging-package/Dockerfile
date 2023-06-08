FROM jenkins/jenkins:jdk11

USER root

COPY scripts/ /opt/scripts/
SHELL ["/bin/bash", "-c"]
RUN apt-get update && apt-get -y upgrade && \ chmod a+x /opt/scripts/install-plugins.sh && \ /opt/scripts/install-plugins.sh
#RUN apt-get update && apt-get -y upgrade && \ /opt/scripts/install-plugins.sh
USER jenkins