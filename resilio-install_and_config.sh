#!/bin/sh
# Author;
# License:

# truquillos para construir el script
# $HOME $USER
#
# grep --color (colorea el resultado del grep)
# read {variable} / clear / export - para listar las variables definidas / exit 1
#
# function
# $(date +%H%M) - means "substitute the output from the date +%H%M command here.


echo '*** Validating requirements ***'
echo 'This script is intented for x86_64 machines'
echo 'Remmemer to run this script as root or using sudo'
# ToDo; validar si es x86_64 y si no salir con mensaje de error
# ToDo; validar si es root y si no salir con mensaje de error



echo
echo
echo "*** Installing Resilio Sync ***"
# Variables definition
RESILIO_REPO_KEY='https://linux-packages.resilio.com/resilio-sync/key.asc'
RESILIO_REPO_X86_64='https://linux-packages.resilio.com/resilio-sync/rpm/x86_64'
RESILIO_PACKAGE_NAME='resilio-sync'

# Import repository key
# ToDo: Revisar si es realmente necesario importar el key
rpm --import $RESILIO_REPO_KEY
# Add repository
echo 'Adding resilio repository ('$RESILIO_REPO_X86_64')'
zypper ar -cfp 90 $RESILIO_REPO_X86_64 resilio
# Install resilio package
echo 'Installing '$RESILIO_PACKAGE_NAME' package'
zypper install $RESILIO_PACKAGE_NAME

echo 'Installation finished'
# rslsync user and group should have been created.


echo
echo
echo '*** Generation of own certificates and move to user config directory ***'
# Generate own certificates

RESILIO_USER_HOME_DIR='/home/rslsync'
RESILIO_USER_HOME_DIR_CONFIG=$RESILIO_USER_HOME_DIR'/.config/resilio-sync'
RESILIO_CONFIG_DIR='/etc/resilio-sync'
RESILIO_SERVICE_DIR='/lib/systemd/system'

echo 'Generating ssl key and certificate'
# Genera un certificados y claves (duración en días -days)
openssl req -newkey rsa:4096 -nodes -keyout private.key -x509 -days 3650 -out cert.pem

# Move generated files to user configuration directory
mkdir -p $RESILIO_USER_HOME_DIR_CONFIG
mv cert.pem $RESILIO_USER_HOME_DIR_CONFIG
mv private.key $RESILIO_USER_HOME_DIR_CONFIG

# Only owner (rslsync) can rw the files
chown -R rslsync:rslsync $RESILIO_USER_HOME_DIR_CONFIG
#chmod -R 600 $RESILIO_USER_HOME_DIR_CONFIG
chmod -R u+rwX,g-rX,o-rX $RESILIO_USER_HOME_DIR_CONFIG

echo 'Generation of own certificates and move to user config directory finished'

# /lib/systemd/system/resilio-sync.service


echo
echo
echo 'Configuring config.json'
mkdir -p $RESILIO_USER_HOME_DIR'/.resilio-sync/.sync'
# Only owner (rslsync) can rw the files in resilio data directory
chown -R rslsync:rslsync $RESILIO_USER_HOME_DIR'/.resilio-sync'
#chmod -R 644 $RESILIO_USER_HOME_DIR'/.resilio-sync'
chmod -R u+rwX,g+rX,o+rX $RESILIO_USER_HOME_DIR'/.resilio-sync'

mv $RESILIO_CONFIG_DIR'/config.json' $RESILIO_CONFIG_DIR'/config.json.bak'
cp ./res/config.json $RESILIO_CONFIG_DIR'/config.json'


# (A)ccept, (S)kip, for(g)et
echo '****Specify a Device Name in order to identify this computer.(Defaul; '$(hostname) ')'
read _name
# ToDo:
# to check it is not empty
# https://stackoverflow.com/questions/3061036/how-to-find-whether-or-not-a-variable-is-empty-in-bash
#  sed -i '0,/{/a\"device_name\" : \"valor\",' $RESILIO_CONFIG_DIR'/config.json'

# ToDo: Pedir usuario y password, luego crypt e insertar dentro de estructura webui dentro de config.json
#  no se que algoritmo usa MDE5 - openssl passwd -1 ...
# echo -n "password" | openssl dgst -sha256
#
# /* preset credentials. Use password or password_hash */
# //  ,"login" : "admin"
# //  ,"password" : "password"
# //  ,"password_hash" : "some_hash" // password hash in crypt(3) format
# //  ,"allow_empty_password" : false // Defaults to true
# /* ssl configuration */


chown root:root $RESILIO_CONFIG_DIR'/config.json'
chmod 644 $RESILIO_CONFIG_DIR'/config.json'

echo 'Configuration config.json finished'

echo
echo
echo 'Configuring resilio-sync.service'
# RESILIO_SERVICE_DIR'/resilio-sync.service'
# Probar, igual no hace falta, en el fichero original pone PIDFile=%h/.config/resilio-sync/sync.pid
# sed -i.bak 's/PIDFile.*/PIDFile=\/home\/rslsync\/.resilio-sync\/sync.pid/g' RESILIO_SERVICE_DIR'/resilio-sync.service'
sed -i.bak 's/PIDFile.*/PIDFile=\/home\/rslsync\/.resilio-sync\/sync.pid/g' $RESILIO_SERVICE_DIR'/resilio-sync.service'



systemctl enable resilio-sync
systemctl start resilio-sync
systemctl status resilio-sync








# ToDo: no funciona del todo bien, no tengo claro si nunca o sólo la primera vez
#rpm --import $RESILIO_REPO_KEY
# Create file resilio-sync-repo.repo and locate it at /etc/zypp/repos.d/
# si copiamos el fichero a mano igual no hay que darlo de alta igual con zypper;
# sudo zypper ar -cfp 90 $RESILIO_REPO_X86_64
#sudo zypper install $RESILIO_PACKAGE_NAME

# Ejecutamos configuración por defecto. Debería crear el fichero
# $HOME/.config/resilio-sync/config.json con un contenido del tipo;
# {
#    "storage_path" : "{HOME}/.config/resilio-sync/storage",
#    "pid_file" : "{HOME}/.config/resilio-sync/sync.pid",
#
#    "webui" :
#    {
#        "listen" : "127.0.0.1:8888"
#    }
# }
# Referencia al fichero de configuración
# https://help.resilio.com/hc/en-us/articles/206178884-Running-Sync-in-configuration-mode
# y ejemplo completo de fichero; http://internal.resilio.com/support/sample.conf
#
# Referencia a storage path (almacena temporales, database, etc;
# https://help.resilio.com/hc/en-us/articles/206664690-Sync-Storage-folder
