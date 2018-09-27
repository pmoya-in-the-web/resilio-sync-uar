#!/bin/sh

# ToDo: is it really needed?
#rpm --import $RESILIO_REPO_KEY
# Referencia al fichero de configuración
# https://help.resilio.com/hc/en-us/articles/206178884-Running-Sync-in-configuration-mode
# y ejemplo completo de fichero; http://internal.resilio.com/support/sample.conf
#
# Referencia a storage path (almacena temporales, database, etc;
# https://help.resilio.com/hc/en-us/articles/206664690-Sync-Storage-folder


echo '*** Validating requirements ***'
# Checks if the user running the script is root
if [ $EUID != 0 ];
  then
    echo -e "\e[1;31mPlease run as root (try using 'su' or 'sudo' )'\e[0m"
    exit 1
  else
    echo 'Script is runned by "root" user'
fi

# Checks if your computer architecture is valid
_ARCH=$(uname -a)
if [[ $_ARCH == *"x86_64"* ]];
  then
    echo 'Architecture: '$_ARCH
  else
    echo -e "\e[1;31mSORRY!! This script is intended for x86_64 architectures\e[0m"
    exit 1
fi

# Checks if resilio is already installed on your system
RESILIO_PACKAGE_FIND=$(rpm -qa resilio-sync)
if [[ $RESILIO_PACKAGE_FIND ]];
  then
    echo -e "\e[1;31mPlease remove resilio-sync first (uninstall manually or run uninstall script)\e[0m"
    exit 1
  else
    echo 'It seems that resilio-sync is not installed on your system'
fi

# Variables definition
RESILIO_REPO_KEY='https://linux-packages.resilio.com/resilio-sync/key.asc'
RESILIO_REPO_X86_64='https://linux-packages.resilio.com/resilio-sync/rpm/x86_64'
RESILIO_PACKAGE_NAME='resilio-sync'
RESILIO_USER_HOME_DIR='/home/rslsync'
RESILIO_USER_HOME_DIR_4SED='\/home\/rslsync'
RESILIO_USER_HOME_DIR_CONFIG=$RESILIO_USER_HOME_DIR'/.config/resilio-sync'
RESILIO_CONFIG_DIR='/etc/resilio-sync'
RESILIO_SERVICE_DIR='/lib/systemd/system'
RESILIO_SSL_PRIVATE_KEY_FILE='private.key'
RESILIO_SSL_CERT_FILE='cert.pem'


echo
echo
echo "*** Installing Resilio Sync ***"


# Import repository key
# ToDo: Check if it really needed
rpm --import $RESILIO_REPO_KEY
# Add repository
echo 'Adding resilio repository ('$RESILIO_REPO_X86_64')'
zypper ar -cfp 90 $RESILIO_REPO_X86_64 resilio
# Install resilio package
echo 'Installing '$RESILIO_PACKAGE_NAME' package'
zypper --non-interactive --no-gpg-checks install $RESILIO_PACKAGE_NAME

echo '*** Installation finished ***'
# rslsync user and group should have been created.


echo
echo
echo '*** Generation of own certificates and move to user config directory ***'
# Generate own certificates

echo 'Generating ssl key and certificate'
# Genera un certificados y claves (duración en días -days)
openssl req -newkey rsa:4096 -nodes -keyout $RESILIO_SSL_PRIVATE_KEY_FILE -x509 -days 3650 -out $RESILIO_SSL_CERT_FILE

# Move generated files to user configuration directory
mkdir -p $RESILIO_USER_HOME_DIR_CONFIG
mv $RESILIO_SSL_PRIVATE_KEY_FILE $RESILIO_USER_HOME_DIR_CONFIG
mv $RESILIO_SSL_CERT_FILE $RESILIO_USER_HOME_DIR_CONFIG

# Only owner (rslsync) can rw the files
chown -R rslsync:rslsync $RESILIO_USER_HOME_DIR_CONFIG
#chmod -R 600 $RESILIO_USER_HOME_DIR_CONFIG
chmod -R u+rwX,g-rX,o-rX $RESILIO_USER_HOME_DIR_CONFIG

echo 'Generation of own certificates and move to user config directory finished'

# /lib/systemd/system/resilio-sync.service

echo
echo
echo 'Configuring '$RESILIO_CONFIG_DIR'/config.json'
mkdir -p $RESILIO_USER_HOME_DIR'/.resilio-sync/.sync'
# Only owner (rslsync) can rw the files in resilio data directory
chown -R rslsync:rslsync $RESILIO_USER_HOME_DIR'/.resilio-sync'
#chmod -R 644 $RESILIO_USER_HOME_DIR'/.resilio-sync'
chmod -R u+rwX,g+rX,o+rX $RESILIO_USER_HOME_DIR'/.resilio-sync'

#cp $RESILIO_CONFIG_DIR'/config.json' $RESILIO_CONFIG_DIR'/config.json.bak'
# cp ./res/config.json $RESILIO_CONFIG_DIR'/config.json'


# Specify a device name for this computer
echo -n 'Specify a device name to identify this computer and press [ENTER](Default: "'$(hostname)'"]: '
read _DEVICE_NAME
if [[ -z $_DEVICE_NAME ]];
  then
    _DEVICE_NAME=$(hostname)
fi
# Append device name and generates .bak file
sed -i.bak '0,/{/a\   "device_name\" : \"'$_DEVICE_NAME'\",' $RESILIO_CONFIG_DIR'/config.json'

# Configure storage_path
sed -i '/storage_path/c\   \"storage_path\" : \"'$RESILIO_USER_HOME_DIR'\/.resilio-sync\/.sync\",' $RESILIO_CONFIG_DIR'/config.json'
# Configure pid_file path
sed -i '/pid_file/c\   \"pid_file\" : \"'$RESILIO_USER_HOME_DIR'\/.resilio-sync\/sync.pid\",' $RESILIO_CONFIG_DIR'/config.json'
# Set https only
sed -i -e '/}/ {i\       ,"force_https" : true' -e ':a' -e '$!{n;ba' -e '};}' $RESILIO_CONFIG_DIR'/config.json'
# Set path to ssl configuration (key and certificate)
sed -i -e '/}/ {i\       ,"ssl_certificate" : \"'$RESILIO_USER_HOME_DIR_CONFIG'/'$RESILIO_SSL_CERT_FILE'\"' -e ':a' -e '$!{n;ba' -e '};}' $RESILIO_CONFIG_DIR'/config.json'
sed -i -e '/}/ {i\       ,"ssl_private_key" : \"'$RESILIO_USER_HOME_DIR_CONFIG'/'$RESILIO_SSL_PRIVATE_KEY_FILE'\"' -e ':a' -e '$!{n;ba' -e '};}' $RESILIO_CONFIG_DIR'/config.json'

# ToDo: Ask for user and password (use crypt
#       Some investigation needed: how to crypt? algorithm?
#       echo -n "password" | openssl dgst -sha256
#
# /* preset credentials. Use password or password_hash */
# //  ,"login" : "admin"
# //  ,"password" : "password"
# //  ,"password_hash" : "some_hash" // password hash in crypt(3) format
# //  ,"allow_empty_password" : false // Defaults to true
# /* ssl configuration */


#chown root:root $RESILIO_CONFIG_DIR'/config.json'
#chmod 644 $RESILIO_CONFIG_DIR'/config.json'

echo 'Configuration config.json finished'

echo
echo
echo 'Configuring '$RESILIO_SERVICE_DIR'resilio-sync.service'
# Change .pid file location
sed -i.bak -e 's/PIDFile.*/PIDFile='\"$RESILIO_USER_HOME_DIR_4SED'\/.resilio-sync\/sync.pid\"/g' $RESILIO_SERVICE_DIR'/resilio-sync.service'

# Enable and start service
# echo '- Enabling and starting resilio service'
( set -x;
  systemctl enable resilio-sync
  systemctl start resilio-sync
)
