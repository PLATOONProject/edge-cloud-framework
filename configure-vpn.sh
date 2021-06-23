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

# Install and run a VPN server.
OVPN_DATA="ovpn-data-platoon"
docker volume create --name $OVPN_DATA
docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u "udp://${CLOUD_IP}"
docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki

docker stop openvpn
docker rm openvpn
docker run -v $OVPN_DATA:/etc/openvpn -d --name openvpn --restart=always -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn

# Generate VPN config files.
mkdir vpn_configs
while read -r <&3 line; do
  host=$(echo "$line" | tr -d '[:space:]')
  echo "Generating VPN config for ${host}"

  docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full "${host}" nopass
  docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient "${host}" > "vpn_configs/${host}.ovpn"
done 3< nodes.txt