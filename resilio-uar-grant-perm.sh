#!/bin/sh

# ToDo: change owner and group from rslsync to user

ACTION=$1
DIR=$2

if [[ "--help" == "$1" ]]; then
  echo "Find, add or remove rwX ACL permissions to a directory (recursive) for rslsync group"
  echo "Usage: $0 -{find|add|rm} {directory}"
  echo "All arguments are mandatory."
  echo " -find      Find files and directories with rslsync ACL (user or group)"
  echo " -add       Add ACL rwX (if it was set before) permissions for rslsync group"
  echo " -rm        Remove ACL rwx permissions for rslsync user or group"
  echo ""
  echo " directory  Directory to apply permissions (recursively) "
  exit 1
fi

echo 'Checking if "'$DIR'" exist'
if [[ -d "$DIR" ]]; then
  echo 'Directory exists'
else
  if [[ -f "$DIR" ]]; then
    echo 'File exists'
  else
    echo 'It is NOT a directory nor file'
    exit 1
  fi
fi

case "$ACTION" in
  -find)
    echo "Finding files and directories for rslsync rwx user ACL starting at "$DIR":"
    getfacl -Rs $DIR | awk -v RS= '/\nuser:rslsync:rwx\n/ {sub(/\n.*/, ""); sub(/^[^:]*: /, ""); print}'
    echo "Finding files and directories for rslsync rwx group ACL starting at "$DIR":"
    getfacl -Rs $DIR | awk -v RS= '/\ngroup:rslsync:rwx\n/ {sub(/\n.*/, ""); sub(/^[^:]*: /, ""); print}'
    echo "** Done"
    ;;
  -add)
    echo "Grant rslsync user ACL recursively to "$DIR
    setfacl -R -m g:rslsync:rwX $DIR
    ;;
  -rm)
    echo "Remove rslsync user or group ACL recursively to "$DIR
    setfacl -R -x user:rslsync $DIR
    setfacl -R -x group:rslsync $DIR
    ;;
  *)
    echo "Usage: $0 -{find|add|rm} {directory}"
    echo "Try with --help option to get more info"
    exit 1
esac


# ToDo: Asignar permisos a rslsync sobre los directorios que vayamos a modificar
# parámetroso como comando linux grant y remove o en dos scripts
#
# Let’s say you selected your home folder /home/your-username/ as the shared folder.
# To fix the above error, all you need to do is to grant permissions on your
# home folder to the rslsync user with the following command.
#     sudo setfacl -R -m "u:rslsync:rwx" /home/your-usernameThe
# above command won’t change the owner of the shared folder.
# The owner has the same permissions as usual.
# What it does is to grant read, write and execute permissions to one more user,
# namely rslsync. Note that -R (recursive) flag must come before -m (modify)
#  flag, which is immediately followed by the access control list entry
# (u:rslsync:rwx).

# grant-persmisions-to-shared-directories

# find directories
#   getfacl -Rs /varios | awk -v RS= '/\nuser:rslsync:rwx\n/ {sub(/\n.*/, ""); sub(/^[^:]*: /, ""); print}'


# Remove files owned by user ? find / -user rslsync - find / -group rslsync
# ToDo: Beware not to delete shared files
