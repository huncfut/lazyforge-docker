#!/bin/bash
# ┏━━━━━┓
# ┃ ENV ┃
# ┗━━━━━┛
MINECRAFT_VERSION=1.19.2
SERVER_DIR=server
LAZYMC_VERSION=0.2.10
FORGE_VERSION=43.2.8
PROTOCOL=760
EULA=true

ARCH=$(arch)
if [ "$ARCH" == "x86_64" ]; then ARCH=x64; fi

LAZYMC_DOWNLOAD_LINK=https://github.com/timvisee/lazymc/releases/download/v${LAZYMC_VERSION}/lazymc-v${LAZYMC_VERSION}-linux-${ARCH}
LAZYMC_PATH=lazymc
LAZYMC_CONFIG_PATH=${LAZYMC_PATH}.toml
START_SERVER_PATH=${SERVER_DIR}/start_server.sh

FORGE_DOWNLOAD_LINK=https://maven.minecraftforge.net/net/minecraftforge/forge/${MINECRAFT_VERSION}-${FORGE_VERSION}/forge-${MINECRAFT_VERSION}-${FORGE_VERSION}-installer.jar
FORGE_INSTALLER_PATH=installer.jar



# ┏━━━━━━━┓
# ┃ UTILS ┃
# ┗━━━━━━━┛
S_H1="\033[33;1m"
S_H2="\033[36;1m"
S_R="\033[0m"

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
      chmod a+x ${LAZYMC_PATH}
    else 
      echo "Lazymc download failed. Abort..."
      exit 10
  fi
}

# ========= CONFIG LAZYMC =========
function config_lazymc {
  # -- PUBLIC
  echo "[public]" > ${LAZYMC_CONFIG_PATH}
  echo "version = \"${MINECRAFT_VERSION}\"" >> ${LAZYMC_CONFIG_PATH}
  echo "protocol = ${PROTOCOL}" >> ${LAZYMC_CONFIG_PATH}

  # -- SERVER
  echo "[server]" >> ${LAZYMC_CONFIG_PATH}
  echo "directory = \"${SERVER_DIR}\"" >> ${LAZYMC_CONFIG_PATH}
  echo "command = \"bash start_server.sh\"" >> ${LAZYMC_CONFIG_PATH}
  echo "forge = true" >> ${LAZYMC_CONFIG_PATH}

  # -- MOTD
  echo "[motd]" >> ${LAZYMC_CONFIG_PATH}
  echo "sleeping = \"☠ Server is sleeping\n§2☻ Join to start it up\"" >> ${LAZYMC_CONFIG_PATH}
  echo "starting = \"§2☻ Server is starting...\n§7⌛ Please wait...\"" >> ${LAZYMC_CONFIG_PATH}
  echo "stopping = \"☠ Server going to sleep...\n⌛ Please wait...\"" >> ${LAZYMC_CONFIG_PATH}

  # -- CONFIG
  echo "[config]" >> ${LAZYMC_CONFIG_PATH}
  echo "version = \"${LAZYMC_VERSION}\"" >> ${LAZYMC_CONFIG_PATH}
}

# ========= CREATE STARTING SCRIPT =========
function create_starting_script {
  echo "trap 'kill -TERM \$PID' TERM INT" > ${START_SERVER_PATH}
  cat ${SERVER_DIR}/run.sh | grep -v ^# | sed "s/\".*/--nogui \&/" >> ${START_SERVER_PATH}
  echo 'PID=$!' >> ${START_SERVER_PATH}
  echo 'wait $PID' >> ${START_SERVER_PATH}
  echo 'trap - TERM INT' >> ${START_SERVER_PATH}
  echo 'wait $PID' >> ${START_SERVER_PATH}
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
echo -e "${S_H1}LAZYFORGE-DOCKER STARTING UP!!!${S_R}"

# -- FORGE
echo -e "\n${S_H2}CHECK FORGE${S_R}"
if [ -f "${SERVER_DIR}/run.sh" ]
  then
    echo "Found run.sh"
  else
    echo "No run.sh script detected. Installing Forge"
    download_forge
    install_forge
    echo "eula=${EULA}" > ${SERVER_DIR}/eula.txt
    touch ${SERVER_DIR}/server.properties
fi

# -- LAZYMC
echo -e "\n${S_H2}CHECK LAZYMC${S_R}"
if [ -f "${LAZYMC_PATH}" ]
  then
    echo "Lazymc installed"
  else
    echo "Lazymc not detected. Downloading Lazymc"
    download_lazymc
fi
if [ -f "${LAZYMC_CONFIG_PATH}" ]
  then
    echo "Lazymc config found"
  else
    echo "Creating lazymc config"
    config_lazymc
fi
if [ -f "${START_SERVER_PATH}" ]
  then
    echo "Starting script found"
  else
    echo "Creating startup script"
    create_starting_script
fi

echo "Starting UP!"
exec ./lazymc