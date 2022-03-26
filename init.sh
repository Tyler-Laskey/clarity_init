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

addToLogDt "Initializing Clarity development environment" 1
exit 2
mkdir -p staging

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   addToLogDt "Script must be run as root"
   exit 1
fi

SECTION="docker"
echo "Importing ${SECTION} keyring"
addToLogDt "Checking ${SECTION} keyring"
# import docker key
if [ -e /usr/share/keyrings/docker-archive-keyring.gpg ]; then
  echo "-${SECTION} keyring exists"
  addToLogDt "-${SECTION} keyring exists"
else
  addToLogDt "-${SECTION} keyring missing"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o staging/ubuntu-gpg |& tee -a .log
  cat staging/ubuntu-gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg |& tee -a .log
  if ! [ -e /usr/share/keyrings/docker-archive-keyring.gpg ]; then
    echo "-Unable to pull ${SECTION} keyring"
    addToLogDt "-!!! Unable to load ${SECTION} keyring !!!"
    exit
  else
    echo "-${SECTION} keyring pulled successfully"
    addToLogDt "-${SECTION} keyring pulled successfully"
  fi
fi
echo "Checking ${SECTION} source"
addToLogDt "Checking ${SECTION} source"
if [ -e /etc/apt/sources.list.d/docker.list ]; then
  echo "-${SECTION} source exists"
  addToLogDt "-${SECTION} source exists"
else
  echo "-Adding ${SECTION} source"
  addToLogDt "-Adding ${SECTION} source"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi





exit 1



# import kubernetes keys
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

# # import helm keys
# count=$(grep -c "kafkacat" ~/.bash_aliases)
# curl https://baltocdn.com/helm/signing.asc -o helm_signing.asc & apt-key add helm_signing.asc
# echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
# rm -f helm_signing.asc

# apt update
# apt upgrade -y



# if [ -e /etc/apt/sources.list.d/helm-stable-debian.list ]; then
# > echo "true"
# > else
# > echo false
# > fi
# true



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