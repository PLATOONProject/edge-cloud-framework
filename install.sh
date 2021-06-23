#!/bin/bash

# Check if running as root.
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)."
  exit 1
fi

# Parse command line args.
while getopts i: flag
do
    case "${flag}" in
        i) CLOUD_IP=${OPTARG};;
    esac
done

# Check if all required arguments are provided.
if [ -z "$CLOUD_IP" ]; then
  echo "Please provide an IP of the cloud server."
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

# Create a docker swarm.
docker swarm leave --force 
docker swarm init --advertise-addr $CLOUD_IP > /dev/null && echo "Created a Docker swarm"
SWARM_TOKEN=$(docker swarm join-token worker --quiet)

f_node=$(cat node-template.sh)
f_node="${f_node/SWARM_TOKEN/$SWARM_TOKEN}"
f_node="${f_node/CLOUD_IP/$CLOUD_IP}"
echo "$f_node" > node.sh

# Add edge nodes to the swarm.
while read -r <&3 line; do
  host=$(echo "$line" | tr -d '[:space:]')
  echo "Connecting to ${host}"
  scp ./node.sh "${host}:"
  ssh -t "$host" "chmod u+x node.sh; sudo ./node.sh"
done 3< nodes.txt

# Install Portainer.
curl -L https://downloads.portainer.io/portainer-agent-stack.yml -o portainer-agent-stack.yml
docker stack deploy -c portainer-agent-stack.yml portainer

# Install Rundeck.
docker volume create rundeck_data
docker stop rundeck
docker rm rundeck
docker run -d --name rundeck --restart=always -e RUNDECK_GRAILS_URL=/. -p 4440:4440 -v rundeck_data:/home/rundeck/server/data -v "${HOME}/.ssh":/home/rundeck/.ssh rundeck/rundeck:3.4.0