#!/bin/bash

if ( [ "CLOUD_SHELL" == "true" ] || [ "GOOGLE_CLOUD_SHELL" == "true" ] ) ; then
	echo "ERROR: This script is meant to be run locally, i.e. on the client, not within Cloud Shell"
	exit 1
fi

if [ -z "$(which sshfs)" ] ; then
	echo "ERROR: No sshfs executable found. Aborting."
	[ -n "$(which sudo)" ] && echo 'INFO: Call this script with "'$0' --init" to install sshfs (requires sudo rights).'
	exit 1
elif [ -z "$(which sshfs)" ] && [ "$1" == "--init" ] ; then
	echo "Attempting to install sshfs."
	sudo apt install sshfs -y
fi

if ! mkdir -p ~/sshfs ; then
	echo 'ERROR: Could not create sshfs mount point "~/sshfs". Aborting.'
	exit 1
fi
SESSIONS_FILE="~/.x2go/gcs-sessions"
CLOUD_OUTPUT=""
while ! echo -e "$CLOUD_OUTPUT" | grep -q '^sshfs'; do
	CLOUD_OUTPUT=$(gcloud cloud-shell get-mount-command ~/sshfs)
done
SSH_USER=$(echo -e "$CLOUD_OUTPUT" | tr ':@' '  ' | awk '$1=="sshfs" {print $2 }')
SSH_IP=$(echo -e "$CLOUD_OUTPUT" | tr ':@' '  ' | awk '$1=="sshfs" {print $3 }')
SSH_PORT=$(echo -e "$CLOUD_OUTPUT" | awk '$1=="sshfs" {print $5 }')
SSH_KEYFILE=$(echo -e "$CLOUD_OUTPUT" | tr '=' ' ' | awk '$1=="sshfs" {print $7 }')
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
CLOUD_OUTPUT=$(echo $CLOUD_OUTPUT | sed -e "s#$SSH_IP:#$SSH_IP:/#")

if [ -z "$SSH_AGENT_PID" ] || [ -z "$SSH_AUTH_SOCK" ] ; then
	eval $(ssh-agent)
fi
PUBKEYFPRINT=$(ssh-keygen -l -f ${SSH_KEYFILE}.pub)
if ! ssh-add -l | grep -q "$PUBKEYFPRINT" ; then
	ssh-add $SSH_KEYFILE
fi

if grep 'fuse.sshfs' /proc/mounts | grep "${HOME}/sshfs " | grep -q "${SSH_USER}@${SSH_IP}:/" ; then
	# we're already mounted, nothing to do
	echo "INFO: Already mounted"
	CLOUD_OUTPUT=""
elif grep 'fuse.sshfs' /proc/mounts | grep -q "${HOME}/sshfs " ; then
	echo 'WARNING: Something else is already mounted on mount point "~/sshfs". Attempting umount.'
	if fusermount -u ~/sshfs ; then
	       echo 'INFO: Umount succeeded.'
	else
		echo 'ERROR: Could not umount "~/sshfs". Aborting.'
		exit 1
	fi
fi
if [ -n "$CLOUD_OUTPUT" ]; then
	if ! eval $($CLOUD_OUTPUT) ; then
		echo 'ERROR: Could not mount "~/sshfs". Aborting.'
		exit 1
	else
		echo 'INFO: Mount succeeded.'
	fi
fi
# "source" remote config file
if [ -s ~/sshfs/home/${SSH_USER}/.gcs-x2go ] ; then
	eval $(test -s ~/sshfs/home/${SSH_USER}/.gcs-x2go && cat ~/sshfs/home/${SSH_USER}/.gcs-x2go | grep -v "^ *#" 2>/dev/null)
elif [ "$1" == "--init" ] ; then
	echo 'export SERVER_USE_ROOT=true
export USEX2GOREPO=stable
export SERVERNAME=demobox
export CHROOTDEBVERSION="bookworm"
export USERNAME=jdoe
export USERREALNAME="John Doe"' >  ~/sshfs/home/${SSH_USER}/.gcs-x2go
	echo 'INFO: Created minimal, generic config file.'
else
	echo 'ERROR: Config file ~/sshfs/home/"'${SSH_USER}'"/.gcs-x2go not found. Aborting.'
	echo 'INFO: Call this script with "'$0' --init" to use a minimal, generic config file.'
	exit 1
fi

if [ -d ~/sshfs/home/${SSH_USER}/google-cloud-x2go-server ] ; then
	echo 'INFO: Found remote git/script directory.'
elif [ "$1" == "--init" ] ; then
	echo 'INFO: Will now create remote git/script directory.'
	git clone $(grep url ../.git/config | awk -F'=' '{ print $2 }')  ~/sshfs/home/${SSH_USER}/google-cloud-x2go-server/
else
	echo 'ERROR: git/script directory ~/sshfs/home/"'${SSH_USER}'"/google-cloud-x2go-server not found. Aborting.'
	echo 'INFO: Call this script with "'$0' --init" to run git clone the repo into that directory.'
	exit 1
fi

if [ -x ~/sshfs/home/${SSH_USER}/gopath/bin/stopserver ] ; then
	echo 'INFO: At least one of our scripts is executable and in the default search path on the remote end.'
elif [ "$1" == "--init" ] ; then
	echo 'INFO: Will now replace the old gopath directory with our own.'
	if [ -e ~/sshfs/home/${SSH_USER}/gopath ]; then
		mv ~/sshfs/home/${SSH_USER}/gopath ~/sshfs/home/${SSH_USER}/old_gopath
	fi
	(cd ~/sshfs/home/${SSH_USER} ; ln -sf gopath google-cloud-x2go-server/gopath)
else
	echo 'ERROR: Our scripts are not executable and/or not in the default search path on the remote end. Aborting.'
	echo 'INFO: Call this script with "'$0' --init" to try to automatically fix this by moving "~/sshfs/home/'${SSH_USER}'/gopath" somewhere else.'
	exit 1
fi

if ! [ -x ~/sshfs/${SERVERNAME}/bin/bash ]; then
	FREEZER_STATE=$(ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP '(test -s ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'.tar.xz || test -s ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'-backup.tar.xz) 2>/dev/null || echo "EMPTYFREEZER"')

	if [ "$FREEZER_STATE" == "EMPTYFREEZER" ] ; then
		if [ "$1" == "--init" ] ; then
			echo 'INFO: Attempting to create a new server instance.'
			ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP '~/gopath/bin/createserver >/dev/null' 2>/dev/null
		else
			echo 'ERROR: No frozen server image found. Aborting.'
			echo 'INFO: Call this script with "'$0' --init" to create a new server instance.'
			exit 1
		fi
	else
		echo 'INFO: Frozen server image found.'
	fi
	# if both our frozen images exist, do nothing, else try to hardlink the first with the second; if that fails, the second with the first
	ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP '! (test -s ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'.tar.xz && test -s ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'-backup.tar.xz) && sudo ln ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'-backup.tar.xz ~/'"${SERVERNAME}"'-home/'${SERVERNAME}'.tar.xz ' 2>/dev/null
	ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP '! (test -s ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'.tar.xz && test -s ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'-backup.tar.xz) && sudo ln ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'.tar.xz ~/'"${SERVERNAME}"'-home/'${SERVERNAME}'-backup.tar.xz' 2>/dev/null

	# Start thawing the server
	echo 'INFO: Attempting to thaw the server.'
	ssh -t -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP '~/gopath/bin/thawserver 2>&1 | tee ~/thawserver-log' 2>/dev/null || exit 1
else
	echo 'INFO: Server directory already present, attempting to use that'
fi

# Spawn the server
ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP '~/gopath/bin/startserver-google-jumphost >/dev/null' 2>/dev/null

# Add PUBKEY to default user, if not already present
PUBKEY=$(cat ${SSH_KEYFILE}.pub)
if ! grep -q "$PUBKEY" ~/sshfs/${SERVERNAME}/home/${USERNAME}/.ssh/authorized_keys ; then
	echo "$PUBKEY">> ~/sshfs/${SERVERNAME}/home/${USERNAME}/.ssh/authorized_keys
fi

REMOTEUSERLIST=$(echo -e "${USERNAME}\n$(ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP 'sudo chroot /'"${SERVERNAME}"' getent group users' 2>/dev/null | awk -F ':' '{ print $4 }' | tr ',' '\n')" | sort -u | tr '\n' ' ')

echo 'INFO: Creating X2Go Session Config file in "~/.x2goclient/gcs-sessions".'

mkdir -p ~/.x2goclient
# create empty file
: > ~/.x2goclient/gcs-sessions
for REMOTEUSER in $REMOTEUSERLIST; do
	if [ "$REMOTEUSER" == "$USERNAME" ] ; then
		AUTOLOGINSTATE="true"
		AUTOLOGINKEY="$SSH_KEYFILE"
	else
		AUTOLOGINSTATE="false"
		AUTOLOGINKEY=""
	fi
	TIMESTAMP_HEADER=$(date +%F%T%N | tr -d -c '[:digit:]' | cut -b 1-15)
        sed     -e "s/TIMESTAMP/$TIMESTAMP_HEADER/" \
                -e "s/USERNAME/$REMOTEUSER/g" \
                -e "s/AUTOLOGINSTATE/$AUTOLOGINSTATE/g" \
                -e "s#AUTOLOGINKEY##g" \
                -e "s/PROXYIP/$SSH_IP/" \
                -e "s/PROXYPORT/$SSH_PORT/" \
                -e "s/GCLOUDACCOUNT/$SSH_USER/" \
                -e "s#GCLOUDKEYFILE##" \
		~/sshfs/home/${SSH_USER}/google-cloud-x2go-server/clientside/gcs-session-template >> ~/.x2goclient/gcs-sessions
		#-e "s#AUTOLOGINKEY#$AUTOLOGINKEY#g" \
		#-e "s#GCLOUDKEYFILE#$SSH_KEYFILE#" \
done

echo 'INFO: Starting X2GoClient.'
x2goclient --session-conf=~/.x2goclient/gcs-sessions >/dev/null 2>&1 & 

echo 'INFO: Please leave this shell open and cause some activity in it to keep the connection alive.'
ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP 2>/dev/null

