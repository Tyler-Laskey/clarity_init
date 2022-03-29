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
  if ! [ -e $1 ]; then 
    STAGING=$1
    addToLogDt "path not passed in to proxyPrep function"
    exit 0
  fi
  addToLogDt "Applying 'fix' for proxy so that wsl is able to access corp VPN" y

  proxyPrepWindows $STAGING

  
  # check if the wsl config exists
  if [ -e /etc/wsl.conf ]; then
    # We only need to do something if this is missing
    TXT=$(cat /etc/wsl.conf | grep generateResolveConf)
    if [ -z "$TXT" ]; then 
      printf "[network]\ngenerateResolveConf = false\n" | tee -a /etc/wsl.conf
    fi
  else
    printf "[network]\ngenerateResolveConf = false\n" | tee /etc/wsl.conf
  fi

  curl -fsSL https://raw.githubusercontent.com/Tyler-Laskey/clarity_init/main/wsl_dns.py -o $STAGING/wsl_dns.py
  cp -f ~/staging/wsl_dns.py /opt/wsl_dns.py
  chmod +x /opt/wsl_dns.py
}

proxyPrepWindows()
{
  if ! [ -e $1 ]; then 
    STAGING=$1
    addToLogDt "path not passed in to proxyPrep function"
    exit 0
  fi
  addToLogDt "-Grabbing windows portion of proxy patch" y

  TMP_PROXY=/tmp
  PROXY_WIN=/mnt/c/wsl
  
  if [ -e "$TMP_PROXY/corp-proxy" ];then
    rm -rf $TMP_PROXY/corp-proxy
  fi
  if [ -e "$PROXY_WIN/corp_proxy" ];then
    rm -rf $PROXY_WIN/corp_proxy
  fi
  
  # mkdir -p $TMP_PROXY
  mkdir -p $PROXY_WIN/corp_proxy

  cd $TMP_PROXY
  git clone https://github.com/Tyler-Laskey/corp-proxy
  cp -r $TMP_PROXY/corp-proxy/* $PROXY_WIN/corp_proxy
  addToLogDt "-Windows portion of proxy patch is download into c:\wsl\corp_proxy" y
}

initSystemd()
{ 
  if ! [ -e $1 ]; then 
    STAGING=$1
    addToLogDt "path not passed in to initSystemd function"
    exit 0
  fi
  proxyPrep $STAGING

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
  if ! [ -e $1 ]; then 
    STAGING=$1
    addToLogDt "path not passed in to initKeyrings function"
    exit 0
  fi

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
  if ! [ -e $1 ]; then 
    STAGING=$1
    addToLogDt "path not passed in to installHelm function"
    exit 0
  fi
  addToLogDt "Checking Helm install"
  
  if ! [ -e /usr/local/bin/helm ];then
    addToLogDt "-Helm not detected, installing..." y
    HELM_VERSION=helm-v3.4.1-linux-amd64.tar.gz
    cd $STAGING
    rm -rf $HELM_VERSION
    rm -rf linux-amd64*
    wget https://get.helm.sh/$HELM_VERSION
    tar xvf $HELM_VERSION
    cp linux-amd64/helm /usr/local/bin
  else
    addToLogDt "-Helm detected, skipping install" y
  fi
    
}

installMinikube()
{
  addToLogDt "Checking minikube install"
  if ! [ -e $1 ]; then 
    STAGING=$1
    addToLogDt "path not passed in to installMinikube function"
    exit 0
  fi
  
  if ! [ -e /usr/local/bin/minikube ];then
    addToLogDt "- Minikube not detected, installing..." y
    cd $STAGING
    sudo rm -r minikube*
    wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    cp minikube-linux-amd64 /usr/local/bin/minikube
    chmod 755 /usr/local/bin/minikube
  else
    addToLogDt "-Minikube detected, skipping install" y
  fi
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

configureDocker()
{
  printf "${USER} ALL=(ALL) NOPASSWD: /usr/bin/dockerd\n" >> /etc/sudoers
}









STAGING=/tmp/staging
mkdir -p $STAGING
initSystemd $STAGING
initKeyrings $STAGING

installPackages
installHelm $STAGING
installMinikube $STAGING

configureDocker
source ~/.bashrc
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
