#!/bin/bash

# Check if running as root.
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)."
  exit 1
fi

# Check if docker is running.
docker info > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Docker daemon is not available."
  
  echo "Trying to run docker..."
  systemctl enable docker
  systemctl start docker

  sleep 6
fi

docker info > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Docker daemon cannot be run."
  
  echo "Installing docker..."
  # Install docker (assumes Ubuntu Linux).
  apt-get remove docker docker-engine docker.io containerd runc
  apt-get update
  apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
fi

docker swarm leave --force
docker swarm join --token SWARM_TOKEN CLOUD_IP:2377