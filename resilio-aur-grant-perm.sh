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
