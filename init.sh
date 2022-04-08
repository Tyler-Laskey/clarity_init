#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   addToLogDt "This script must be run as root" y
   exit 1
fi
# As this script must be run as root, we can get the running username via that variable $SUDO_USER
SUDO_HOME=/home/$SUDO_USER
CLARITY_HOME=$SUDO_HOME/clarity
CONVERTED_PATH=''

# Variables that can be updated as new versions are released
HELM_VERSION=helm-v3.4.1-linux-amd64.tar.gz
JLESS_FILE=jless-v0.8.0-x86_64-unknown-linux-gnu.zip
JLESS_URL=https://github.com/PaulJuliusMartinez/jless/releases/download/v0.8.0/jless-v0.8.0-x86_64-unknown-linux-gnu.zip
MINIKUBE_URL=https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# add a message to the log file
addToLog() {
  MSG=$1
  ECHO=$2
  if ! [ -z $ECHO ]; then
    echo "${MSG}"
  fi
  printf "${MSG}\n" >> .log
}

# Stamp datetime infront of message
addToLogDt() {
  MSG=$1
  ECHO=$2
  if ! [ -z $ECHO ]; then
    echo "${MSG}"
  fi
  addToLog "$(date "+%y/%m/%d %H:%M:%S") | ${MSG}"
}

configureDocker() {
  DOCKER_STATUS=$(sudo -l -U $SUDO_USER | grep dockerd -c)
  if [ "$DOCKER_STATUS" == 0 ]; then
    printf "${SUDO_USER} ALL=(ALL) NOPASSWD: /usr/bin/dockerd\n" >> /etc/sudoers
  fi
}

covertWinPath() {
    # Converts Windows paths to WSL/Ubuntu paths, prefixing /mnt/driveletter and preserving case of the rest of the arguments,
    # replacing backslashed with forwardslashes
    # example: 
    # Input -> "C:\Share"
    # Output -> "/mnt/j/Share"
    # echo "Input --> $1" #for debugging
    CONVERTED_PATH=$(sed -e 's#^\(.\):#/mnt/\L\1#' -e 's#\\#/#g' <<< "$1")
    #Group the first character at the beginning of the string. e.g. "C:\Share", select "C" by using () but match only if it has colon as the second character
    #replace C: with /mnt/c
    #\L = lowercase , \1 = first group (of single letter)
    # 2nd part of expression
    #replaces every \ with /, saving the result into the var line. 
    #Note it uses another delimiter, #, to make it more readable.
    # echo "Output --> $line" #for debugging
    # cd "$line" #change to that directory
}

generateAliases() {
  # Create aliases if not existing
  touch /home/$SUDO_USER/.bash_aliases

  count=$(grep -c "kafkacat" /home/$SUDO_USER/.bash_aliases)
  if [$count == 0];then
    echo 'alias kcat="kafkacat"' >> /home/$SUDO_USER/.bash_aliases
  fi

  # Create aliases if not existing
  count=$(grep -c "python3" /home/$SUDO_USER/.bash_aliases)
  if [$count == 0];then
    echo 'alias py3="python3"' >> /home/$SUDO_USER/.bash_aliases
  fi

  # Create aliases if not existing
  count=$(grep -c "psx" /home/$SUDO_USER/.bash_aliases)
  if [$count == 0];then
    echo "alias psx='ps aux | grep -v grep'" >> /home/$SUDO_USER/.bash_aliases
  fi
}

installHelm() {
  if ! [ -e $1 ]; then 
    STAGING=$1
    addToLogDt "path not passed in to installHelm function"
    exit 0
  fi
  addToLogDt "Checking Helm install"
  
  if ! [ -e /usr/local/bin/helm ];then
    addToLogDt "-Helm not detected, installing..." y
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

installJless() {
  if ! [ -e $1 ]; then 
    STAGING=$1
    addToLogDt "path not passed in to installJless function"
    exit 0
  fi

  if ! [ -e /usr/local/bin/jless ];then
    addToLogDt "-jless not detected, installing..." y
    cd $STAGING
    rm -rf jless*
    wget $JLESS_URL
    unzip $JLESS_FILE
    mv jless /usr/local/bin/jless
  else
    addToLogDt "-jless detected, skipping install" y
  fi
}

installMinikube() {
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
    wget $MINIKUBE_URL
    cp minikube-linux-amd64 /usr/local/bin/minikube
    chmod 755 /usr/local/bin/minikube
  else
    addToLogDt "-Minikube detected, skipping install" y
  fi
}

installPackages() {
  addToLogDt "Installing required apps" y
  apt update
  apt upgrade
  apt install -y -f containerd
  apt install -y -f apt-transport-https ca-certificates conntrack docker-ce docker-ce-cli containerd.io python3 python3-pip python3-venv kafkacat jq unzip libxcb1-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev curl gnupg lsb-release kubectl
  apt autoremove -y
}

initKeyrings() {
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

initSystemd() { 
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
    addToLogDt "Windows portion of proxy patch is download into c:\wsl\corp_proxy" y
    addToLogDt "" y
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

proxyPrep() {
  addToLogDt "Applying 'fix' for proxy so that wsl is able to access corp VPN" y
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
  TMP_PROXY=$TMP_PROXY/corp-proxy
  cp -r $TMP_PROXY/* $PROXY_WIN/corp_proxy
  addToLogDt "-Windows portion of proxy patch is download into c:\wsl\corp_proxy" y
  
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

  # curl -fsSL https://raw.githubusercontent.com/Tyler-Laskey/clarity_init/main/wsl_dns.py -o $STAGING/wsl_dns.py
  cp -f $TMP_PROXY/wsl_dns.py /opt/wsl_dns.py
  chmod +x /opt/wsl_dns.py
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

STAGING=/tmp/staging
mkdir -p $STAGING
initSystemd $STAGING
initKeyrings $STAGING

installPackages
installJless $STAGING
installHelm $STAGING
installMinikube $STAGING
configureDocker

source $SUDO_HOME/.bashrc

addToLogDt "InitializingPython..." y
./initPython.sh
addToLogDt "Initialization complete!!!" y
exit
