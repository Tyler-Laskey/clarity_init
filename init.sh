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
    addToLogDt "***Please quit ubuntu and relaunch. Once complete run this init.sh script again.***" y
    exit
  else
    addToLogDt "- systemd is running."
  fi
}

initKeyrings()
{
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
  addToLogDt "${SECTION} complete" y


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
  addToLogDt "${SECTION} complete" y


  SECTION="Helm"
  addToLogDt "Checking ${SECTION} keyring" y

  SRC_URL="https://baltocdn.com/helm/signing.asc"
  KEYRING="/usr/share/keyrings/kubernetes-archive-keyring.gpg"
  ST_FILE="staging/helm_signing.asc"
  LST="/etc/apt/sources.list.d/helm-stable-debian.list"
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
  addToLogDt "${SECTION} complete" y
}

installPackages()
{
  addToLogDt "Installing required apps" y
  apt install -y apt-transport-https ca-certificates conntrack docker-ce docker-ce-cli containerd containerd.io python3 python3-pip python3-venv kafkacat jq unzip libxcb1-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev ca-certificates curl gnupg lsb-release apt-transport-https kubectl helm 
}

installMinikube()
{
  addToLogDt "Installing minikube" y
  wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o staging/minikube
  cp minikube /usr/local/bin/minikube
  chmod +x /usr/local/bin/minikube

}


addToLogDt "Initializing Clarity development environment" y



mkdir -p staging

if [[ $EUID -ne 0 ]]; then
   addToLogDt "This script must be run as root" y
   exit 1
fi


initSystemd
initKeyrings

installPackages
installMinikube



addToLogDt "Initialization complete!!!" y
exit









# run cleanup to remove staging folder
cleanUp
exit 1


# This command will add the current username to the sudoers file
# printf "${USER} ALL=(ALL) NOPASSWD: /usr/bin/dockerd\n" >> /etc/sudoers





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
