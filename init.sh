#!/bin/bash

# add a message to the log file
addToLog()
{
  MSG=$1
  ECHO=$2
  if ! [ -z $ECHO ]; then
    echo "${MSG}"
  fi
  printf "${MSG}\n" >> .log
}

# Stamp datetime infront of message
addToLogDt()
{
  MSG=$1
  ECHO=$2
  if ! [ -z $ECHO ]; then
    echo "${MSG}"
  fi
  addToLog "$(date "+%y/%m/%d %H:%M:%S") | ${MSG}"
}

cleanUp()
{
  rm -r staging/
}

initSystemd()
{
  addToLogDt "Ensuring systemd is running before continuing" y
  if [ -z $(ps aux | grep -v grep | grep systemd) ]; then
    addToLogDt "- systemd is not running. Begining install..." y
    git clone https://github.com/Tyler-Laskey/ubuntu-wsl2-systemd-script.git ~/ubuntu-wsl2-systemd-script
    cd ~/ubuntu-wsl2-systemd-script
    bash install.sh --force
    addToLogDt "- Please quit ubuntu and restart. Once complete run this init.sh script again." y
    exit
  else
    addToLogDt "- systemd is running."
  fi
}





addToLogDt "Initializing Clarity development environment" e



mkdir -p staging

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   addToLogDt "Script must be run as root"
   exit 1
fi

initSystemd

SECTION="docker"
addToLogDt "Checking ${SECTION} keyring" y

SRC_URL="https://download.docker.com/linux/ubuntu/gpg"
KEYRING="/usr/share/keyrings/docker-archive-keyring.gpg"
ST_FILE="staging/docker-gpg"
LST="/etc/apt/sources.list.d/docker.list"

# import docker key
if [ -e ${KEYRING} ]; then
  addToLogDt "-${SECTION} keyring exists" y
else
  addToLogDt "-${SECTION} keyring missing"
  curl -fsSL ${SRC_URL} -o ${ST_FILE}|& tee -a .log
  cat ${ST_FILE} | gpg --dearmor -o ${KEYRING} |& tee -a .log
  if ! [ -e ${KEYRING} ]; then
    echo "-Unable to pull ${SECTION} keyring"
    addToLogDt "-!!! Unable to load ${SECTION} keyring !!!"
    exit
  else
    addToLogDt "-${SECTION} keyring pulled successfully" y
  fi
fi
addToLogDt "Checking ${SECTION} source" y
if [ -e ${LST} ]; then
  addToLogDt "-${SECTION} source exists" y
else
  addToLogDt "-Adding ${SECTION} source" y
  echo "deb [arch=$(dpkg --print-architecture) signed-by=${KEYRING}] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list |& tee -a .log
fi
echo "${SECTION} complete"


SECTION="kubernetes"
addToLogDt "Checking ${SECTION} keyring" y

SRC_URL="https://packages.cloud.google.com/apt/doc/apt-key.gpg"
KEYRING="/usr/share/keyrings/kubernetes-archive-keyring.gpg"
ST_FILE="staging/kubernetes-gpg"
LST="/etc/apt/sources.list.d/kubernetes.list"

# import Kubernetes key
if [ -e ${KEYRING} ]; then
  addToLogDt "-${SECTION} keyring exists" y
else
  addToLogDt "-${SECTION} keyring missing" y
  curl -fsSL ${SRC_URL} -o ${ST_FILE} |& tee -a .log
  cat ${ST_FILE} | gpg --dearmor -o ${KEYRING} |& tee -a .log
  if ! [ -e ${KEYRING} ]; then
    echo "-Unable to pull ${SECTION} keyring"
    addToLogDt "-!!! Unable to load ${SECTION} keyring !!!"
    exit
  else
    addToLogDt "-${SECTION} keyring pulled successfully" y
  fi
fi
addToLogDt "Checking ${SECTION} source" y
if [ -e ${LST} ]; then
  addToLogDt "-${SECTION} source exists" y
else
  addToLogDt "-Adding ${SECTION} source" y
  echo "deb [signed-by=${KEYRING}] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee ${LST} |& tee -a .log
fi
echo "${SECTION} complete"


SECTION="Helm"
addToLogDt "Checking ${SECTION} keyring" y

SRC_URL="https://baltocdn.com/helm/signing.asc"
KEYRING="/usr/share/keyrings/kubernetes-archive-keyring.gpg"
ST_FILE="staging/helm_signing.asc"
LST="/etc/apt/sources.list.d/helm-stable-debian.list"

# import Kubernetes key
if [ -e ${KEYRING} ]; then
  addToLogDt "-${SECTION} keyring exists" y
else
  addToLogDt "-${SECTION} keyring missing" y
  curl -fsSL ${SRC_URL} -o ${ST_FILE} |& tee -a .log
  apt-key add ${ST_FILE}
  if ! [ -e ${KEYRING} ]; then
    echo "-Unable to pull ${SECTION} keyring"
    addToLogDt "-!!! Unable to load ${SECTION} keyring !!!"
    exit
  else
    addToLogDt "-${SECTION} keyring pulled successfully" y
  fi
fi
addToLogDt "Checking ${SECTION} source" y
if [ -e ${LST} ]; then
  addToLogDt "-${SECTION} source exists" y
else
  addToLogDt "-Adding ${SECTION} source" y
  echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee ${LST} |& tee -a .log
fi
echo "${SECTION} complete"










# run cleanup to remove staging folder
cleanUp
exit 1




# count=$(grep -c "kafkacat" ~/.bash_aliases)

# apt update
# apt upgrade -y


# # Create aliases if not existing
# count=$(grep -c "kafkacat" ~/.bash_aliases)
# if [$count == 0];then
#   echo 'alias kcat="kafkacat"' >> ~/.bash_aliases
# fi

# # Create aliases if not existing
# count=$(grep -c "python3" ~/.bash_aliases)
# if [$count == 0];then
#   echo 'alias py3="python3"' >> ~/.bash_aliases
# fi

# TST_EXIST=cat ~/.bash_aliases | grep kafkacat
