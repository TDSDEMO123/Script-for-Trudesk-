#!/bin/bash

#Colors settings
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

#Welcome message
echo -e "Welcome to Trudesk Install Script!
Lets make sure we have all the required packages before moving forward..."

echo -e "Setting Clock..."
timedatectl
NTP=$(dpkg-query -W -f='${Status}' ntp 2>/dev/null | grep -c "ok installed")
  if [ $(dpkg-query -W -f='${Status}' ntp 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo -e "${YELLOW}Installing ntp${NC}"
    apt-get install ntp --yes;
    elif [ $(dpkg-query -W -f='${Status}' ntp 2>/dev/null | grep -c "ok installed") -eq 1 ];
    then
      echo -e "${GREEN}ntp is installed!${NC}"
  fi

#Checking packages
echo -e "${YELLOW}Checking packages...${NC}"
echo -e "List of required packeges: git, wget, python, curl, nodejs, npm"

read -r -p "Do you want to check packeges? [y/N]: " response </dev/tty

case $response in
[yY]*)
WGET=$(dpkg-query -W -f='${Status}' wget 2>/dev/null | grep -c "ok installed")
  if [ $(dpkg-query -W -f='${Status}' wget 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo -e "${YELLOW}Installing wget${NC}"
    apt-get install wget --yes;
    elif [ $(dpkg-query -W -f='${Status}' wget 2>/dev/null | grep -c "ok installed") -eq 1 ];
    then
      echo -e "${GREEN}wget is installed!${NC}"
  fi
PYTHON=$(dpkg-query -W -f='${Status}' python 2>/dev/null | grep -c "ok installed")
  if [ $(dpkg-query -W -f='${Status}' python 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo -e "${YELLOW}Installing python${NC}"
    apt-get install python --yes;
    elif [ $(dpkg-query -W -f='${Status}' python 2>/dev/null | grep -c "ok installed") -eq 1 ];
    then
      echo -e "${GREEN}python is installed!${NC}"
  fi
CURL=$(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed")
  if [ $(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo -e "${YELLOW}Installing curl${NC}"
    apt-get install curl --yes;
    elif [ $(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed") -eq 1 ];
    then
      echo -e "${GREEN}curl is installed!${NC}"
  fi
GIT=$(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed")
  if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo -e "${YELLOW}Installing git${NC}"
    apt-get install git --yes;
    elif [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 1 ];
    then
      echo -e "${GREEN}git is installed!${NC}"
  fi
NODEJS=$(dpkg-query -W -f='${Status}' nodejs 2>/dev/null | grep -c "ok installed")
  if [ $(dpkg-query -W -f='${Status}' nodejs 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo -e "${YELLOW}Installing nodejs${NC}"
    curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
    apt-get install nodejs --yes;
    apt-get install npm --yes;
    apt-get install build-essential --yes;
    elif [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 1 ];
    then
      echo -e "${GREEN}nodejs is installed!${NC}"
  fi
NODE=$(dpkg-query -W -f='${Status}' nodejs-legacy 2>/dev/null | grep -c "ok installed")
  if [ $(dpkg-query -W -f='${Status}' nodejs-legacy 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo -e "${YELLOW}Installing nodejs-legacy${NC}"
    apt-get install nodejs-legacy --yes;
    elif [ $(dpkg-query -W -f='${Status}' nodejs-legacy 2>/dev/null | grep -c "ok installed") -eq 1 ];
    then
      echo -e "${GREEN}nodejs-legacy is installed!${NC}"
  fi

  ;;

*)
  echo -e "${RED}
  Packeges check is ignored!
  Please be aware that all software packages may not be installed!
  ${NC}"
  ;;
esac

read -r -p "Do you want to install MongoDB locally? [y/N]: " response </dev/tty
case $response in
[yY]*)
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927;
  echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list;
  apt-get update;
  apt-get install -y mongodb-org mongodb-org-shell;
cat >/lib/systemd/system/mongod.service <<EOL
[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target
Documentation=https://docs.mongodb.org/manual

[Service]
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target
EOL
  systemctl enable mongod
  service mongod start

echo "Waiting for MongoDB to start...";
sleep 10

cat >/etc/mongosetup.js <<EOL
db.system.users.remove({});
db.system.version.remove({});
db.system.version.insert({"_id": "authSchema", "currentVersion": 3});
EOL
  mongo /etc/mongosetup.js
  service mongod restart

echo "Restarting MongoDB..."
sleep 5

cat > /etc/mongosetup_trudesk.js <<EOL 
db = db.getSiblingDB('trudesk');
db.createUser({"user": "trudesk", "pwd": "#TruDesk1$", "roles": ["readWrite", "dbAdmin"]});
EOL
  mongo /etc/mongosetup_trudesk.js
  ;;

*)
  echo -e "${RED}MongoDB install skipped...${NC}"
  ;;
esac

echo -e "${YELLOW}Downloading the latest version of ${NC}Trudesk${RED}.${NC}"
cd TicketingMastercode
touch TicketingMastercode/logs/output.log
echo -e "${BLUE}Building...${NC}"
npm install -g yarn pm2 grunt-cli
yarn install
sleep 3
cd TicketingMastercode && npm run build && echo -e "${BLUE}Starting...${NC}" && pm2 start TicketingMastercode/app.js --name trudesk -l TicketingMastercode/logs/output.log --merge-logs && pm2 save && pm2 startup && echo -e "Installation & configuration successfully finished."
