#!/bin/bash
# ┏━━━━━┓
# ┃ ENV ┃
# ┗━━━━━┛
MINECRAFT_VERSION=1.19.2
SERVER_DIR=server
LAZYMC_VERSION=0.2.10
FORGE_VERSION=43.2.8

LAZYMC_DOWNLOAD_LINK=https://github.com/timvisee/lazymc/releases/download/v${LAZYMC_VERSION}/lazymc-v${LAZYMC_VERSION}-linux-x64
LAZYMC_PATH=lazymc

FORGE_DOWNLOAD_LINK=https://maven.minecraftforge.net/net/minecraftforge/forge/${MINECRAFT_VERSION}-${FORGE_VERSION}/forge-${MINECRAFT_VERSION}-${FORGE_VERSION}-installer.jar
FORGE_INSTALLER_PATH=installer.jar

# ┏━━━━━━━┓
# ┃ UTILS ┃
# ┗━━━━━━━┛
# S_H="\033[33;1m"
# S_R="\033[0m"

# ========= PROCESS SPINNER UTIL =========
# -- $1 is the message
# -- $2 is the PID of the process
function process_spinner {
  SPINNER=⠧⠏⠛⠹⠼⠶
  i=0

  while ps -p $2 > /dev/null; do
    if [ $i -eq ${#SPINNER} ]; then i=0; fi
    echo -ne "\r$1 ${SPINNER:$i:1}"
    sleep 0.1
    ((i++))
  done
  echo -e "\r$1: DONE"
}


# ┏━━━━━━━━┓
# ┃ LAZYMC ┃
# ┗━━━━━━━━┛
# ========= DOWNLOAD LAZYMC =========
function download_lazymc {
  if wget ${LAZYMC_DOWNLOAD_LINK} -q --show-progress -O ${LAZYMC_PATH}
    then 
      echo "Lazymc downloaded succesfully"
    else 
      echo "Lazymc download failed. Abort..."
      exit 10
fi
}


# ┏━━━━━━━━━━━━━━━━━┓
# ┃ MINECRAFT FORGE ┃
# ┗━━━━━━━━━━━━━━━━━┛
# ========= DOWNLOAD FORGE INSTALLER =========
function download_forge {
  if wget ${FORGE_DOWNLOAD_LINK} -q --show-progress -O ${FORGE_INSTALLER_PATH}
    then 
      echo "Forge downloaded sucessfully"
    else 
      echo "Forge download failed. Abort..."
      exit 20
  fi
}

# ========= INSTALL FORGE =========
function install_forge {
  # Create server directory
  if [ ! -d ${SERVER_DIR} ]; then mkdir ${SERVER_DIR}; fi

  # Run Forge installer inside server directory
  java -jar ${FORGE_INSTALLER_PATH} --installServer ${SERVER_DIR} > /dev/null & process_spinner "Installing Forge" "$!"

  # Determine whether successful
  if [ $? -eq 0 ];
    then
      rm ${FORGE_INSTALLER_PATH}*
      rm ${SERVER_DIR}/run.bat
      FORGE_INSTALLED=1
    else
      echo "Installation Failed"
      exit 21
  fi
}


# ┏━━━━━━━━━━━━━━━━━━━┓
# ┃ MAIN SETUP SCRIPT ┃
# ┗━━━━━━━━━━━━━━━━━━━┛
# echo -e "${S_H}LAZYFORGE-DOCKER STARTING UP!!!${S_R}"

if [ -L ${LAZYMC_PATH} ]
  then
    echo "Lazymc installed"
  else
    echo "Lazymc not detected. Downloading Lazymc"
    download_lazymc
fi
if [ -L ${SERVER_DIR}/run.sh ]
  then
    echo "Starting server"
  else
    echo "No run.sh script detected. Installing Forge"
    download_forge
    install_forge
fi

echo "Starting UP!"
exec ./${LAZYMC_PATH}