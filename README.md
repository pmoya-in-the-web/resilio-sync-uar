# resilio-sync-uar
Get Resilio Sync Home (https://www.resilio.com/individuals/) Up and Running (UAR) on your home computer ruled by opensuse ( https://www.opensuse.org/ ).

This is an UNOFFICIAL script for install, configure and run resilio-sync on opensuse ( https://www.opensuse.org/ ).

Use those simple script in order to get resilio-sync up and running on opensuse

# Scripts

## Install & Configure - resilio-uar.sh

### Features
- Installation
- Configuration (basic to medium complexity level )
- Start as a service


## Grant & revoke file permissions to files & directories - resilio-uar-grant-perm.sh
### Features
- Find files and directories for rslsync rwx user ACL
- Grant rslsync user ACL recursively
- Remove rslsync user or group ACL recursively

### How to use it
Usage: `resilio-uar-grant-perm.sh -{find|add|rm} {directory}`

Try with `resilio-uar-grant-perm.sh --help` option to get more info


## Uninstall - resilio-uar-uninstall.sh
This script uninstall resilio-sync package and removes all its configuration.


# Tested opensuse versions
- opensuse 15.0 ( OK )
- opensuse 42.3 ( OK )
