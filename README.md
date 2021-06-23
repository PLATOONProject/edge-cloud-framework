# PLATOON Edge-Cloud Framework

The Edge-Cloud Framework is composed of tools for deploying Docker services and managing/automating the edge/cloud infrastructure. The Framework consists of the following tools:

- Portainer - an open source tool for managing containerized applications [[documentation](https://documentation.portainer.io/)]
- Rundeck - an open source service for running automation tasks across a set of nodes [[documentation](https://docs.rundeck.com/docs/manual/01-introduction.html)]

The Framework deployment installs and configures the tools, sets up SSH keys and a VPN on a cloud server, as well as the edge nodes. 


# Prerequisites

The Framework installation assumes the following:

- A static IP for the cloud server that is reachable from the edge nodes
- Open ports between the cloud server and the edge nodes (simplified if using VPN):
  - UDP port 1194 for incoming VPN server connections
  - TCP port 22 for SSH connections
  - TCP port 2377 for Docker cluster management communications
  - TCP and UDP port 7946 for communication among Docker nodes
  - UDP port 4789 for Docker overlay network traffic
- A Linux OS on cloud server and edge nodes (the Framework has been tested with Ubuntu Server 20.04.2 LTS, but should work on other versions with little to no adaptation)
- A user with root privileges on cloud server and edge nodes.


# Framework Installation

To install the Edge-Cloud Framework, please follow the steps below.

## 0. Download the Framework

Download (use the download button > Download ZIP and unzip) or clone this repository to the cloud server.

    git clone git@github.com:platoon/edge-cloud-framework.git

Before proceeding, please make sure you are inside the downloaded directory and `configure-vpn.sh` / `configure-ssh.sh` / `install.sh` scripts are executable.

    cd edge-cloud-framework
    sudo chmod +x configure-vpn.sh
    sudo chmod +x configure-ssh.sh
    sudo chmod +x install.sh

## 1. Specify the edge nodes

During the installation of the Edge-Cloud Framework, SSH connections will be established with edge nodes for configuration purposes. To correctly configure all edge nodes, please provide a list of SSH connection strings in `nodes.txt` for all edge nodes. Provide one connection string per line in the following format: `user@host`.

For example:

    ubuntu@192.168.1.2
    testuser@192.168.1.5

If the nodes are not accessible from the cloud server, provide a list of nodes names and proceed to step 2. The node names may be completely arbitrary, but should be distinct. Example:

    edgenode1
    edgenode2

## 2. Create a VPN (optional)

This step can be skipped if the edge nodes are reachable from the cloud server. Nevertheless, setting up a VPN does provide additional flexibility and security. It also avoids the possible problems with opening ports.

To install and configure a VPN server on the cloud server, run the script on the cloud server by providing the public IP of the cloud server using the `-i` flag.

    sudo ./configure-vpn.sh -i CLOUD_IP

For example:

    sudo ./configure-vpn.sh -i 192.168.1.1

The script will create a client VPN config in `vpn_configs` directory for each node listed in `nodes.txt` that may be used to connect to the VPN server. Leave blank or enter a password where prompted.

Next, install OpenVPN and use the generated config on each edge node to connect to the VPN server (replace `CLIENTCONFIG.ovpn` with respective config generated for each client, enter previously defined password if required):

    sudo apt-get install openvpn
    sudo openvpn --config CLIENTCONFIG.ovpn

The client VPN IP address can be obtained by running the `ip addr ls` or `ifconfig -a` commands and searching for the `tun` interface, e.g.,:

<pre>
tun0    Link encap:UNSPEC  HWaddr 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00
        <b>->inet addr:10.8.0.1<-</b>  P-t-P:10.8.0.1  Mask:255.255.255.0
        UP POINTOPOINT RUNNING NOARP MULTICAST  MTU:1500  Metric:1
        RX packets:8726841 errors:0 dropped:0 overruns:0 frame:0
        TX packets:7897879 errors:0 dropped:22138 overruns:0 carrier:0
        collisions:0 txqueuelen:100
        RX bytes:6123986424 (6.1 GB)  TX bytes:6479665617 (6.4 GB)
</pre>
    
After configuring all edge nodes, edit the `nodes.txt` file using the configured VPN IPs to form connection strings. For instance:

    ubuntu@192.168.254.2
    testuser@192.168.254.5

## 3. Configure SSH keys

This step can be skipped if the edge nodes are reachable from the cloud server and a pair of SSH keys has been set up for connecting to edge nodes from the cloud (i.e., a key pair has been generated and added to the ssh-agent on the cloud server and edge nodes permit SSH connection for holders of said keys).

To configure SSH keys, run the script on the cloud server. Running this script will generate a key pair in `$HOME/.ssh/` named `platoon_key` (private) and `platoon_key.pub` (public). These keys will be added to the cloud server's ssh-agent and edge nodes specified in `nodes.txt`.

    ./configure-ssh.sh

Optionally, if using an existing key pair or specifying the name/location of the key files is desired, the `-f` flag can be used:

    ./configure-ssh.sh -f /path/to/key/my_own_name_key

To avoid generating a new key pair, use the `-c` flag to run this script in configuration-only mode. The edge nodes will be configured using the `$HOME/.ssh/platoon_key` (default) or custom key provided using the `-f` flag.

    ./configure-ssh.sh -f /path/to/key/my_own_name_key -c

Depending on your setup, the script might prompt you for sudo passwords of edge nodes' users or to confirm key fingerprints during the installation. Type `yes` or enter password and press `enter` where appropriate.

**BEWARE:** If `$HOME/.ssh/platoon_key` or the key provided using the `-f` flag already exists, the script will issue a warning and ask whether to overwrite the key. Please make sure you don't overwrite any existing valuable keys and possibly lose access to some service, device or server.

## 4. Install the Framework

To install the Framework, run the script on the cloud server by providing the VPN (if configured) or alternatively the public IP of the cloud server using the `-i` flag.

    sudo ./install.sh -i CLOUD_IP

For example:

    sudo ./install.sh -i 192.168.1.1

Depending on your setup, the script might prompt you for sudo passwords of edge nodes' users or to confirm key fingerprints during the installation. Type `yes` or enter password and press `enter` where appropriate.


# Framework Usage

Upon installing the Framework on the cloud server, navigate to http://localhost:4440/ to access Rundeck. Portainer will expose the UI over the port 9000: http://localhost:9000/. When accessing Portainer for the first time, a prompt for setting up an admin password will appear.

The login credentials for Rundeck will be by default set as:

**Username:** admin

**Password:** admin

Please note that the automatic configuration of the edge nodes in Rundeck is not yet available (TODO).


# Author and License

The Edge-Cloud Framework was compiled by Timotej Gale, timotej.gale@comsensus.eu.

Copyright © 2021 ComSensus, https://www.comsensus.eu/

The research leading to these results has received funding from the European Horizon 2020 Programme project PLATOON under grant agreement No. 872592.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses