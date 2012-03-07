#!/bin/sh
# Quickdoop - by Eric O'Brien

# Absolute path to this script, eg /home/user/bin/install.sh
# this snippet is thanks to:
# http://stackoverflow.com/questions/242538/unix-shell-script-find-out-which-directory-the-script-file-resides
SCRIPT=$(readlink -f $0)
SCRIPTPATH=$(dirname $SCRIPT)

java_path="/usr/lib/jvm/java-6-openjdk"
hadoop_path="/usr/local/hadoop"

echo "Welcome to Quickdoop! This will install hadoop and configure it as a single-node cluster."

echo "Installing java-6-openjdk"
echo "Sit tight, this can take a few minutes to download..."
sudo apt-get --yes install openjdk-6-jdk

echo "Installing openssh-server"
sudo apt-get --yes install openssh-server


# TODO: Allow option that doesn't add a dedicated user
# TODO: don't create the group or the user if they already exist
echo "Adding dedicated hadoop group and user"
sudo addgroup hadoop
sudo echo -e "\n \n \n \n \n \n" | sudo adduser --quiet --disabled-password --ingroup hadoop hduser > /dev/null 2>&1
sudo echo -e "hadoop\nhadoop\n" | sudo passwd --quiet hduser > /dev/null 2>&1

echo "Configuring ssh keys"
if [ ! -f ~hduser/.ssh/id_rsa.pub ] # if keys don't already exist
then
    sudo su hduser -c "ssh-keygen -t rsa -P \"\" -f ~hduser/.ssh/id_rsa -q"
fi
sudo echo "StrictHostKeyChecking=no" >> ~hduser/.ssh/config
sudo cat ~hduser/.ssh/id_rsa.pub >> ~hduser/.ssh/authorized_keys
# adds self to known_hosts without user interaction
sudo su hduser -c "ssh localhost -f \"exit\" "


echo "Installing Hadoop"
# if the hadoop folder already exists where we were planning to put it
if [ -d /usr/local/hadoop ]
then
    echo "It looks like someone already tried to install hadoop here. Would you like to remove the old files and start with a fresh hadoop? Or should we try to continue - hoping that what's there is correct?"
    echo "1 : start fresh (recommended)"
    echo "2 : continue (NOT recommended)"
    echo "ctrl-c : abort install"
    echo "Type your choice and press Enter"
    while read choice
    do
        case "$choice" in
            1 | one | won | fresh) 
                echo "Good choice! Starting fresh."
                echo "Deleting old files"
                sudo rm -rf /usr/local/hadoop
                echo "Unzipping new files"
                sudo tar xzf $SCRIPTPATH/hadoop-1.0.1.tar.gz
                sudo mv $SCRIPTPATH/hadoop-1.0.1 $SCRIPTPATH/hadoop
                echo "Moving files to /usr/local/hadoop"
                sudo mv $SCRIPTPATH/hadoop /usr/local/
                break ;;
            2 | two | too | to)
                echo "Okay... hope this works. Pretending that the hadoop files were installed correctly."
                break ;;
            ctrl-c) 
                echo "That's not exactly what I meant, but okay. Aborting install."
                exit 1 ;;
            *) echo "Invalid input, try again." ;;
        esac
    done
else
    echo "Unzipping files"
    sudo tar xzf $SCRIPTPATH/hadoop-1.0.1.tar.gz
    sudo mv $SCRIPTPATH/hadoop-1.0.1 $SCRIPTPATH/hadoop
    echo "Moving files to /usr/local/hadoop"
    sudo mv $SCRIPTPATH/hadoop /usr/local/
fi

# now we can start using $hadoop_path
# TODO: don't add the lines if they already exist
# they won't exist if we're making a new user, but for the future
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

echo "Done! Try it out by logging in to hduser and using the \"hadoop\" command."