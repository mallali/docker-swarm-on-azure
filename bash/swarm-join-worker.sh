#!/bin/bash
#set -e
#  Joins to a swarm as a worker.
#  Assuming we will have following arguments passed while executing this bash script
#  1. (string)  The IP address of the primary VM - in Azure this is the private NAT address for the VM (typically 10.0.0.5 for example)
#  2. (string)  The user name
#  3. (string)  The password  - The password will be replaced later with SSH - for now we are using this


primaryManagerIP=$1

userName=$2
userPassword=$3
sshHostName=$userName@$primaryManagerIP
storageUrl=$4
storageName=$5
storagePassword=$6

sudo echo "Primary manager IP: $primaryManagerIP"
sudo echo "User: $userName"
sudo echo "Password: $userPassword"
sudo echo "The SSH target is: $sshHostName"

# until apt-get -y update && apt-get -y install apache2 php5 
until sudo docker version 
do
 echo "Docker command not yet available, we are going to wait and retry..."
 sleep 10
done

echo "We have docker installed at this point in time..."
until sudo apt-get -y update &&  sudo apt-get -qq -y install sshpass
do
 echo "Trying to grab a lock for apt-get "
 sleep 2
done

echo "We have installed sshpass.."
sudo apt-get -qq install sshpass -y &&
mynicetoken=$(sudo sshpass -p $userPassword ssh -o StrictHostKeyChecking=no $sshHostName 'sudo docker swarm join-token -q worker')
echo "Our Join token: $mynicetoken"

sudo docker swarm join --token $mynicetoken $primaryManagerIP:2377 &&

echo "Joining as worker is completed..."

sudo mkdir -p /etc/docker 
sudo echo {\"insecure-registries\":[\"docker.zoom-media.nl:5000\"]} > /tmp/daemon.json 
sudo mv -f /tmp/daemon.json /etc/docker/daemon.json && sudo mkdir /mnt/zm-asr-models 
sudo mount -t cifs $4 /mnt/zm-asr-models -o vers=3.0,username=$5,password=$6,dir_mode=0777,file_mode=0777,sec=ntlmssp

sudo service docker restart 

echo "ASR model is mounted and docker is restarted"


