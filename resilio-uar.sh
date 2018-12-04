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

# Specify user and group running resilio for this computer
# ToDo: add as param, if not specified use default user and group
echo -n 'Specify the user will run the service and press [ENTER](Default is \"rslsync:rslsync\"): '
read RESILIO_USER
if [[ -z $RESILIO_USER ]];
then
  RESILIO_USER='rslsync'
  RESILIO_GROUP='rslsync'
else
  echo -n 'Specify group: '
  read RESILIO_GROUP
  if [[ -z $RESILIO_GROUP ]];
  then
    echo -e 'You must specify a valid existing group'
    exit 1
  fi
fi
# ToDo: User and group must be present in the system or be rslsync:rslsync
# if [ `id -u $RESILIO_USER 2>/dev/null || echo -1` -ge 0 ]; then
# echo FOUND
# fi
#
# For user  (>0 user exists)=> getent passwd $RESILIO_USER | grep -c .
# For group (>0 user exists)=> getent passwd $RESILIO_GROUP | grep -c .

# Specify a device name for this computer
# ToDo: add as param, if not specified use hostname
echo -n 'Specify a device name to identify this computer and press [ENTER](Default: "'$(hostname)'"]: '
read DEVICE_NAME
if [[ -z $DEVICE_NAME ]];
then
  DEVICE_NAME=$(hostname)
fi

# Variables definition
RESILIO_REPO_KEY='https://linux-packages.resilio.com/resilio-sync/key.asc'
RESILIO_REPO_X86_64='https://linux-packages.resilio.com/resilio-sync/rpm/x86_64'
RESILIO_PACKAGE_NAME='resilio-sync'

# ToDo: deal with specified user home dir
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
# Generates key and cert (expires in 3650 days)
# openssl req -newkey rsa:4096 -nodes -keyout $RESILIO_SSL_PRIVATE_KEY_FILE -x509 -days 3650 -out $RESILIO_SSL_CERT_FILE
openssl req -newkey rsa:4096 -nodes -keyout $RESILIO_SSL_PRIVATE_KEY_FILE -x509 -days 3650 -out $RESILIO_SSL_CERT_FILE -subj "/C=XX/ST=Resilio Sync/L=mine/O=Me & Myself/OU=Myself/CN=myself.none"

# Move generated files to user configuration directory
mkdir -p $RESILIO_USER_HOME_DIR_CONFIG
mv $RESILIO_SSL_PRIVATE_KEY_FILE $RESILIO_USER_HOME_DIR_CONFIG
mv $RESILIO_SSL_CERT_FILE $RESILIO_USER_HOME_DIR_CONFIG

# Only owner (rslsync) can rw the files
#chown -R rslsync:rslsync $RESILIO_USER_HOME_DIR_CONFIG
chown -R $RESILIO_USER:$RESILIO_GROUP $RESILIO_USER_HOME_DIR_CONFIG

#chmod -R 600 $RESILIO_USER_HOME_DIR_CONFIG
chmod -R u+rwX,g-rX,o-rX $RESILIO_USER_HOME_DIR_CONFIG

echo 'Generation of own certificates and move to user config directory finished'

echo
echo
echo 'Configuring '$RESILIO_CONFIG_DIR'/config.json'
mkdir -p $RESILIO_USER_HOME_DIR'/.resilio-sync/.sync'
# Only owner (rslsync) can rw the files in resilio data directory
chown -R $RESILIO_USER:$RESILIO_GROUP $RESILIO_USER_HOME_DIR'/.resilio-sync'
chmod -R u+rwX,g+rX,o+rX $RESILIO_USER_HOME_DIR'/.resilio-sync'


# Append device name and generates .bak file
sed -i.bak '0,/{/a\   "device_name\" : \"'$DEVICE_NAME'\",' $RESILIO_CONFIG_DIR'/config.json'
# Configure storage_path
sed -i '/storage_path/c\   \"storage_path\" : \"'$RESILIO_USER_HOME_DIR'\/.resilio-sync\/.sync\",' $RESILIO_CONFIG_DIR'/config.json'
# Configure pid_file path
sed -i '/pid_file/c\   \"pid_file\" : \"'$RESILIO_USER_HOME_DIR'\/.resilio-sync\/sync.pid\",' $RESILIO_CONFIG_DIR'/config.json'
# Set https only
sed -i -e '/}/ {i\       ,"force_https" : true' -e ':a' -e '$!{n;ba' -e '};}' $RESILIO_CONFIG_DIR'/config.json'
# Set path to ssl configuration (key and certificate)
sed -i -e '/}/ {i\       ,"ssl_certificate" : \"'$RESILIO_USER_HOME_DIR_CONFIG'/'$RESILIO_SSL_CERT_FILE'\"' -e ':a' -e '$!{n;ba' -e '};}' $RESILIO_CONFIG_DIR'/config.json'
sed -i -e '/}/ {i\       ,"ssl_private_key" : \"'$RESILIO_USER_HOME_DIR_CONFIG'/'$RESILIO_SSL_PRIVATE_KEY_FILE'\"' -e ':a' -e '$!{n;ba' -e '};}' $RESILIO_CONFIG_DIR'/config.json'
echo 'Configuration config.json finished'

echo
echo
echo 'Configuring '$RESILIO_SERVICE_DIR'resilio-sync.service'
# Change .pid file location
sed -i.bak -e 's/PIDFile.*/PIDFile='\"$RESILIO_USER_HOME_DIR_4SED'\/.resilio-sync\/sync.pid\"/g' $RESILIO_SERVICE_DIR'/resilio-sync.service'
# Change the user and group running the service (and ownership when sharing files)
sed -i -e 's/User.*/User='\"$RESILIO_USER'\/.resilio-sync\/sync.pid\"/g' $RESILIO_SERVICE_DIR'/resilio-sync.service'
sed -i -e 's/Group.*/Group='\"$RESILIO_GROUPD'\/.resilio-sync\/sync.pid\"/g' $RESILIO_SERVICE_DIR'/resilio-sync.service'
sed -i -e 's/ExecStartPre.*/ExecStartPre=/bin/chown -R '\"$RESILIO_USER':'$RESILIO_GROUP' /var/run/resilio-sync/g' $RESILIO_SERVICE_DIR'/resilio-sync.service'
# ToDo: give the chance to define your own user or rslsync user.
# if it is your own user is easier but has to add to (check if group users is needed)
# if it is own user maybe rslsync user creation is not needed
# ** no hacer lo del usuario y hacer un cron q actualice los directorios compartidos de vez en cuando por si hay nuevos añadiendo ACL de compartición ??????
# en el cron hacer un chown a usuario:users del directorio raiz compartido y añadir grant ACL
# cómo saber los directorios compartidos??? creo uqe no se puede, no lo deja en el log

# Enable and start service
echo 'Enabling and starting resilio service'
( set -x;
  systemctl enable resilio-sync
  systemctl start resilio-sync
)

echo
echo 'Now resilio should be up and running on your system'
echo '* Resilio service running as '$RESILIO_USER' user and '$RESILIO_GROUP' group'
echo '* Home user directory; '$RESILIO_USER_HOME_DIR
echo '* Configuration file; '$RESILIO_CONFIG_DIR'/config.json'
echo '* Configuration file backup; '$RESILIO_CONFIG_DIR'/config.json.bak'
echo '* Service configuration file; ' $RESILIO_SERVICE_DIR'/resilio-sync-service'
echo 'Try https://127.0.0.1/8888 to acess WebUI (first time access need to define user and password)'
