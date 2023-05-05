#!/bin/bash

MINECRAFT_VERSION=1.19.2
FORGE_VERSION=43.2.8

FORGE_DOWNLOAD_LINK=https://maven.minecraftforge.net/net/minecraftforge/forge/${MINECRAFT_VERSION}-${FORGE_VERSION}/forge-${MINECRAFT_VERSION}-${FORGE_VERSION}-installer.jar
FORGE_INSTALLER=data/installer.jar

echo "Starting download"

# Download Forge installer
if wget ${FORGE_DOWNLOAD_LINK} -q --show-progress --tries=2 -O ${FORGE_INSTALLER};
  then 
    echo "Download succeded";
  else 
    echo "Download failed"
    exit 1
fi

# Run Forge installer
java -jar ${FORGE_INSTALLER} --installServer