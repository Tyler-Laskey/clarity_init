#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# clear

SUDO_HOME=/home/$SUDO_USER
CLARITY_HOME=$SUDO_HOME/clarity

generateLinkedDir(){
  # if clarity exists
  if [ -e clarity ]; then
    RSP=
    until [ $RSP = "y" ] || [ $RSP = "Y" ] || [ $RSP = "n" ] || [ $RSP = "N" ]
    do
      
      echo "### Warning ###"
      echo "Linux path '$CLARITY_HOME' already exists, if you have already run this script, this is normal."
      echo "### Warning ###"
      if ! [ -e $RSP ]; then
        echo "Please enter Y or N to continue."
        echo "Response: $RSP"
      fi
      echo "Would you like to remove '$CLARITY_HOME' so that the folder can be remapped? [y/N]"
      read -r RSP
    done

    if [ $RSP = "y" ] || [ $RSP = "Y" ]; then
      echo "Removing $CLARITY_HOME path"
      rm -f $CLARITY_HOME
    else
      echo "nothing here"
    fi
    
  fi

  # Validate that clarity folder does not exist
  if ! [ -e $CLARITY_HOME ]; then
    echo "This script will create a linked directory to easily find the 'gcp-app-patterning' folder."
    echo "Please drag and drop the folder where you cloned 'gcp-app-patterning' into this window and press ENTER"
    read -r GCP_APP_PATTERNING_PATH
    # echo "You specified '${GCP_APP_PATTERNING_PATH}'"
    
    ln -s $GCP_APP_PATTERNING_PATH $CLARITY_HOME
    chown -R $SUDO_USER:$SUDO_USER $CLARITY_HOME
  # else 

  fi
}

initializePython(){
  cd $CLARITY_HOME
  pythonVenvInstall "$CLARITY_HOME/flow/src"
  pythonVenvInstall "$CLARITY_HOME/jirasync/src"
  pythonVenvInstall "$CLARITY_HOME/pipe/src"
  pythonVenvInstall "$CLARITY_HOME/sink/src"
  pythonVenvInstall "$CLARITY_HOME/source/src"
  pythonVenvInstall "$CLARITY_HOME"
}

pythonVenvInstall(){
  echo "Initializing '$1' venv"
  cd $1
  python3 -m venv venv
  echo "Installing pip packages"
  SUBSHELL=$(
    . $1/venv/bin/activate
    cd $1
    python3 -m pip install wheel
    python3 -m pip install -r requirements.txt > pip_results.txt
  )
  echo "venv install complete, results can be viewed in $1/pip_results.txt"
}

generateLinkedDir
initializePython
