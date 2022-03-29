#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   addToLogDt "This script must be run as root" y
   exit 1
fi

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
  rm -r ~/staging
}

proxyPrep()
{
  addToLogDt "Applying 'fix' for proxy so that wsl is able to access corp VPN" y
  # check if the wsl config exists
  if [ -e /etc/wsl.conf ]; then
    # We only need to do something if this is missing
    TXT=$(cat /etc/wsl.conf | grep generateResolveConf)
    if [ -z "$TXT" ]; then 
      printf "[network]\ngenerateResolveConf = false\n" | tee -a /etc/wsl.conf
    fi
  else echo "not exist"
    printf "[network]\ngenerateResolveConf = false\n" | tee /etc/wsl.conf
  fi

  curl -fsSL https://raw.githubusercontent.com/Tyler-Laskey/clarity_init/main/wsl_dns.py -o ~/staging/wsl_dns.py
  cp -f ~/staging/wsl_dns.py /opt/wsl_dns.py
  chmod +x /opt/wsl_dns.py
}

initSystemd()
{
  proxyPrep

  addToLogDt "Ensuring systemd is running before continuing" y
  SYSD=$(ps aux | grep -v grep | grep systemd)
  if [ -z $SYSD ]; then
    addToLogDt "- systemd is not running. Begining install..." y
    git clone https://github.com/Tyler-Laskey/ubuntu-wsl2-systemd-script.git ~/ubuntu-wsl2-systemd-script
    cd ~/ubuntu-wsl2-systemd-script
    bash install.sh --force
    echo "-------------------------"
    echo "-----!!!ATTENTION!!!-----"
    echo "-------------------------"
    addToLogDt "Please quit ubuntu and run the windows command" y
    addToLogDt "          WSL --Shutdown" y
    addToLogDt "Once complete run this init.sh script again." y
    echo "-------------------------"
    echo "-----!!!ATTENTION!!!-----"
    echo "-------------------------"
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
  ST_FILE="${STAGING}/docker-gpg"
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
  apt update
  addToLogDt "${SECTION} complete" y


  SECTION="kubernetes"
  addToLogDt "Checking ${SECTION} keyring" y

  SRC_URL="https://packages.cloud.google.com/apt/doc/apt-key.gpg"
  KEYRING="/usr/share/keyrings/kubernetes-archive-keyring.gpg"
  ST_FILE="${STAGING}/kubernetes-gpg"
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
  apt update
  addToLogDt "${SECTION} complete" y
}

installPackages()
{
  addToLogDt "Installing required apps" y
  apt update
  apt upgrade
  apt install -y -f containerd
  apt install -y -f apt-transport-https ca-certificates conntrack docker-ce docker-ce-cli containerd.io python3 python3-pip python3-venv kafkacat jq unzip libxcb1-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev ca-certificates curl gnupg lsb-release apt-transport-https kubectl
  apt autoremove -y
}

installHelm()
{
  addToLogDt "Checking Helm install"
  if ! [ -e /usr/local/bin/helm ];then
    addToLogDt "-Helm not detected, installing..." y
    cd $STAGING
    sudo rm -r helm*
    wget https://get.helm.sh/helm-v3.4.1-linux-amd64.tar.gz -o $STAGING/helm-v3.4.1-linux-amd64.tar.gz
    tar xvf helm-v3.4.1-linux-amd64.tar.gz
    mv linux-amd64/helm /usr/local/bin
    rm helm-v3.4.1-linux-amd64.tar.gz
    rm -rf linux-amd64
  else
    addToLogDt "-Helm detected, skipping install" y
  fi
    
}

installMinikube()
{
  addToLogDt "Checking minikube install"
  if ! [ -e /usr/local/bin/minikube ];then
    addToLogDt "- Minikube not detected, installing..." y
    wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o $STAGING/minikube
    cp minikube /usr/local/bin/minikube
    chmod +x /usr/local/bin/minikube
  else
    addToLogDt "-Minikube detected, skipping install" y
  fi
}

addAliases()
{
  addToLogDt "creating aliases" y
  
  touch ~/.bash_aliases

  # if [ -z ${cat ~/.bash_aliases | grep " \\.\\."} ]; then
  #   echo "alias ..='cd ..'" >> ~/.bash_aliases  
  # fi
  
  # if [ -z ${cat ~/.bash_aliases | grep " \.\.\."} ]; then
  #   echo "alias ...='cd ../..'" >> ~/.bash_aliases
  # fi

  if [ -z ${cat ~/.bash_aliases | grep " kcat"} ]; then
    echo "alias kcat='kafkacat'" >> ~/.bash_aliases
  fi

  if [ -z ${cat ~/.bash_aliases | grep " psx"} ]; then
    echo "alias psx='ps aux | grep -v grep'" >> ~/.bash_aliases
  fi
  
  if [ -z ${cat ~/.bash_aliases | grep " py3"} ]; then
    echo "alias py3='python3'" >> ~/.bash_aliases
  fi
  
  # echo "" >> ~/.bash_aliases
  # echo "" >> ~/.bash_aliases
  # echo "" >> ~/.bash_aliases
}

addToLogDt "Initializing Clarity development environment" y

ARG_PROXY=$(echo "$*" | sed 's/[A-Z]/\L&/g' | grep "\-\-proxy")
if ! [ -z $ARG_PROXY ]; then
  addToLogDt "Applying proxy patch" y
  proxyPrep
  echo "-------------------------"
  echo "-----!!!ATTENTION!!!-----"
  echo "-------------------------"
  addToLogDt "Please quit ubuntu and run the windows command" y
  addToLogDt "          WSL --Shutdown" y
  addToLogDt "Once complete run this init.sh script to finish setup." y
  echo "-------------------------"
  echo "-----!!!ATTENTION!!!-----"
  echo "-------------------------"
  exit
fi











STAGING=~/staging
mkdir -p $STAGING
addAliases
initSystemd
initKeyrings

installPackages
installHelm
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













# apt-transport-https
# ca-certificates
# conntrack
# docker-ce
# docker-ce-cli
# containerd
# containerd.io
# python3
# python3-pip
# python3-venv
# kafkacat
# jq
# unzip
# libxcb1-dev
# libxcb-render0-dev
# libxcb-shape0-dev
# libxcb-xfixes0-dev
# ca-certificates
# curl
# gnupg
# lsb-release
# apt-transport-https
# kubectl
