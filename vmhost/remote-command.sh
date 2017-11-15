#!/bin/bash -fue
#
if [ -z "${SSH_ORIGINAL_COMMAND}" ]; then
        echo "This script can only be executed via SSH remote calls"
        exit
fi
 
case "$SSH_ORIGINAL_COMMAND" in
  vboxmanage* )
        $SSH_ORIGINAL_COMMAND
        ;;
  *)
   echo "Bad Command" 
        echo $SSH_ORIGINAL_COMMAND
    ;;
esac
exit
