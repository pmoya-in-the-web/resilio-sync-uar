
# script ejemplo https://github.com/duckinator/signal-desktop-rpm/blob/master/build-rpm.sh


_RESILIO_USER_HOME_DIR_CONFIG=$_RESILIO_USER_HOME_DIR'/.config/resilio-sync'
_RESILIO_CONFIG_DIR='/etc/resilio-sync'
_RESILIO_SERVICE_DIR='/lib/systemd/system'
_RESILIO_USER=rslsync
_RESILIO_GROUP=rslsync



echo 'Removing resilio-sync service'
( set -x;
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
)

# Remove files owned by user ? find / -user rslsync - find / -group rslsync
# ToDo: ojo no me vaya a cargar los ficheros compartidos

# Remove configuration directory
echo 'Removing '$_RESILIO_CONFIG_DIR' directory and service configuration backup files'
rm -r $_RESILIO_CONFIG_DIR
rm $_RESILIO_SERVICE_DIR'/resilio-sync.service.bak'

# Remove user (remove home dir & force)
echo 'Removing '$_RESILIO_USER' user and its home directory'
userdel -rf $_RESILIO_USER
echo 'Removing '$_RESILIO_GROUP' group'
groupdel -f $_RESILIO_GROUP

exit 0
