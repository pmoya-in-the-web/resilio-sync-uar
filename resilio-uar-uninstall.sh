#!/bin/sh

# Checks if the user running the script is root
if [ $EUID != 0 ];
  then
    echo -e "\e[1;31mPlease run as root (try using 'su' or 'sudo' )'\e[0m"
    exit 1
  else
    echo 'Script is runned by "root" user'
fi

# Variables definition
RESILIO_USER_HOME_DIR_CONFIG=$RESILIO_USER_HOME_DIR'/.config/resilio-sync'
RESILIO_CONFIG_DIR='/etc/resilio-sync'
RESILIO_SERVICE_DIR='/lib/systemd/system'
RESILIO_USER=rslsync
RESILIO_GROUP=rslsync

echo 'Removing resilio-sync instalation'
( set -x;
  # Stop service
  systemctl stop resilio-sync
  # Disable service
  systemctl disable resilio-sync

  # Remove resilio-sync software package
  zypper --non-interactive rm resilio-sync

  # Remove resilio repository
  zypper rr resilio
)

echo 'Removing public key from storage'
# Remove repository key
RESILIO_PUBKEY=`rpm -qa gpg-pubkey \* --qf "%{version}-%{release} %{summary}\n" | grep -i resilio | cut -d ' ' -f 1`
sudo rpm -e --allmatches gpg-pubkey-$RESILIO_PUBKEY

# Remove configuration directory
echo 'Removing '$RESILIO_CONFIG_DIR' directory and service configuration backup files'
rm -r $RESILIO_CONFIG_DIR
rm $RESILIO_SERVICE_DIR'/resilio-sync.service.bak'

# Remove user (remove home dir & force)
echo 'Removing '$RESILIO_USER' user and its home directory'
userdel -rf $RESILIO_USER
echo 'Removing '$RESILIO_GROUP' group'
groupdel -f $RESILIO_GROUP
