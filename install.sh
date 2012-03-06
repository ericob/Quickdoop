#!/bin/sh

# Absolute path to this script, eg /home/user/bin/install.sh
# this snippet is thanks to:
# http://stackoverflow.com/questions/242538/unix-shell-script-find-out-which-directory-the-script-file-resides
SCRIPT=$(readlink -f $0)
SCRIPTPATH=$(dirname $SCRIPT)

java_path="/usr/lib/jvm/java-6-openjdk"
hadoop_path="/usr/local/hadoop"

echo "Welcome to Quickdoop! This will install hadoop and configure it as a single-node cluster."

echo "Installing java-6-openjdk"
sudo apt-get -qq install openjdk-6-jdk

echo "Installing openssh-server"
sudo apt-get -qq install openssh-server

echo "Adding dedicated hadoop group and user"
sudo addgroup hadoop
sudo echo -e "\n \n \n \n \n \n" | sudo adduser --quiet --disabled-password --ingroup hadoop hduser
sudo echo -e "hadoop\nhadoop\n" | sudo passwd --quiet hduser 

echo "Configuring ssh keys"
sudo su hduser -c "ssh-keygen -t rsa -P \"\" -f ~hduser/.ssh/id_rsa -q"
sudo echo "StrictHostKeyChecking=no" >> ~hduser/.ssh/config
sudo cat ~hduser/.ssh/id_rsa.pub >> ~hduser/.ssh/authorized_keys

sudo su hduser -c "ssh localhost -f \"exit\" "


echo "Installing Hadoop"

sudo tar xzf $SCRIPTPATH/hadoop-1.0.1.tar.gz
sudo mv $SCRIPTPATH/hadoop-1.0.1 $SCRIPTPATH/hadoop
sudo mv $SCRIPTPATH/hadoop /usr/local/

# now we can start using $hadoop_path

echo "Adding lines to .bashrc"
sudo cat $SCRIPTPATH/modfiles/bashrc_lines >> ~hduser/.bashrc

echo "Modifying hadoop config files"
sudo cat $SCRIPTPATH/modfiles/hadoop-env.sh > $hadoop_path/conf/hadoop-env.sh
sudo cat $SCRIPTPATH/modfiles/core-site.xml > $hadoop_path/conf/core-site.xml
sudo cat $SCRIPTPATH/modfiles/mapred-site.xml > $hadoop_path/conf/mapred-site.xml
sudo cat $SCRIPTPATH/modfiles/hdfs-site.xml > $hadoop_path/conf/hdfs-site.xml

sudo mkdir -p /app/hadoop/tmp
sudo chown hduser:hadoop /app/hadoop/tmp
sudo chmod 750 /app/hadoop/tmp