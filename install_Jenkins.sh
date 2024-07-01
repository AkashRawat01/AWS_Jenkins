#!/bin/bash
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y
sudo apt update -y
sudo apt install fontconfig openjdk-17-jre -y
java -version
sudo "apt-get install -y openssl libssl-dev"
openssl version
sudo apt-get update 
sudo apt install apt-transport-https ca-certificates curl software-properties-common
sudo apt-get install -y dotnet-sdk-8.0
sudo apt-get install -y aspnetcore-runtime-8.0
sudo apt-get install -y dotnet-runtime-8.0
sudo dotnet --version
sudo dotnet --list-runtimes 
sudo apt install zip -y
sudo -s <<EOF
cd /home/ubuntu && mkdir -p soft-file && cd soft-file
wget https://download.visualstudio.microsoft.com/download/pr/e716faa4-345c-45a7-bd1f-860cdf422b75/fa8e57167f3bd4bf20b8b60992cf184f/aspnetcore-runtime-2.2.8-linux-x64.tar.gz
tar xf aspnetcore-runtime-2.2.8-linux-x64.tar.gz -C /usr/lib/dotnet
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg -y
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
wget https://get.helm.sh/helm-v3.15.0-linux-amd64.tar.gz
tar -zxvf helm-v3.15.0-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
EOF
sudo apt install apt-transport-https ca-certificates curl software-properties-common
sudo apt update
sudo apt-cache policy docker-ce
sudo apt install docker-ce -y
sudo apt install maven -y
sudo apt install npm -y
sudo apt install docker-ce -y
sudo dotnet --list-runtimes
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
sudo apt-get install terraform
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword