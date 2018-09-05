
# script ejemplo https://github.com/duckinator/signal-desktop-rpm/blob/master/build-rpm.sh


RESILIO_USER_HOME_DIR_CONFIG=$RESILIO_USER_HOME_DIR'/.config/resilio-sync'
RESILIO_CONFIG_DIR='/etc/resilio-sync'
RESILIO_SERVICE_DIR='/lib/systemd/system'
RESILIO_USER=rslsync
RESILIO_GROUP=rslsync



echo 'Removing resilio-sync service'

# Stop service
systemctl stop resilio-sync
# Disable service
systemctl disable resilio-sync

# Remove resilio-sync software package
zypper rm resilio

# Remove resilio repository
zypper rr resilio

# Remove repository key
# ToDo: rpm --import


# Remove files owned by user ? find / -user rslsync - find / -group rslsync
# ToDo: ojo no me vaya a cargar los ficheros compartidos

# Remove configuration directory
echo 'Removing '$RESILIO_CONFIG_DIR' directory and backup files'
rm -r $RESILIO_CONFIG_DIR
rm $RESILIO_SERVICE_DIR'/resilio-sync.service.bak'

# Remove user (remove home dir & force)
echo 'Removing '$RESILIO_USER' user and its home directory'
userdel -rf $RESILIO_USER
echo 'Removing '$RESILIO_GROUP' group'
groupdel -f $RESILIO_GROUP
