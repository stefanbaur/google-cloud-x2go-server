#!/bin/bash

if ( [ "CLOUD_SHELL" == "true" ] || [ "GOOGLE_CLOUD_SHELL" == "true" ] ) ; then
	echo "ERROR: This script is meant to be run locally, i.e. on the client, not within Cloud Shell"
	exit 1
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
if grep 'fuse.sshfs' /proc/mounts | grep ~/sshfs | grep -q "${SSH_USER}@${SSH_IP}" ; then
	# we're already mounted, nothing to do
	echo "INFO: Already mounted"
	CLOUD_OUTPUT=""
elif grep 'fuse.sshfs' /proc/mounts | grep -q ~/sshfs ; then
	echo 'WARNING: Something else is already mounted on mount point "~/sshfs". Attempting umount.'
	if fusermount -u ~/sshfs ; then
	       echo 'INFO: umount succeeded.'
	else
		echo 'ERROR: Could not umount "~/sshfs". Aborting.'
		exit 1
	fi
fi
if [ -n "$CLOUD_OUTPUT" ]; then
	if ! eval $($CLOUD_OUTPUT) ; then
		echo 'ERROR: Could not mount sshfs. Aborting.'
		exit 1
	fi
fi

# "source" remote config file
eval $(ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP 'test -s ~/.gcs-x2go && cat ~/.gcs-x2go | grep -v "^ *#"' 2>/dev/null)
FREEZER_STATE=$(ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP '(test -s ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'.tar.xz || test -s ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'-backup.tar.xz) || echo "EMPTYFREEZER"')

if [ "$FREEZER_STATE" == "EMPTYFREEZER" ] ; then
	echo 'ERROR: No frozen server image found. Aborting.'
	exit 1
fi

# if both our frozen images exist, do nothing, else try to hardlink the first with the second; if that fails, the second with the first
ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP '! (test -s ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'.tar.xz && test -s ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'-backup.tar.xz) && sudo ln ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'-backup.tar.xz ~/'"${SERVERNAME}"'-home/'${SERVERNAME}'.tar.xz ' 2>/dev/null
ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP '! (test -s ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'.tar.xz && test -s ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'-backup.tar.xz) && sudo ln ~/'"${SERVERNAME}"'-home/'"${SERVERNAME}"'.tar.xz ~/'"${SERVERNAME}"'-home/'${SERVERNAME}'-backup.tar.xz' 2>/dev/null

# Start thawing the server and spawn the instance
ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP '~/gopath/bin/thawserver' 2>/dev/null
ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP '~/gopath/bin/startserver-google-jumphost' 2>/dev/null

REMOTEUSERLIST=$(echo -e "${USERNAME}\n$(ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP 'sudo chroot /'"${SERVERNAME}"' getent group users' 2>/dev/null | awk -F ':' '{ print $4 }' | tr ',' '\n')" | sort -u | tr '\n' ' ')

echo 'INFO: Creating X2Go Session Config file in "~/sshfs/google-cloud-x2go-server/clientside/gcs-sessions".'

mkdir -p ~/.x2goclient
# create empty file
: > ~/.x2goclient/gcs-sessions
for REMOTEUSER in $REMOTEUSERLIST; do
	TIMESTAMP_HEADER=$(date +%F%T%N | tr -d -c '[:digit:]' | cut -b 1-15)
	sed 	-e "s/TIMESTAMP/$TIMESTAMP_HEADER/" \
		-e "s/USERNAME/$REMOTEUSER/g" \
		-e "s/PROXYIP/$SSH_IP/" \
		-e "s/PROXYPORT/$SSH_PORT/" \
		-e "s/GCLOUDACCOUNT/$SSH_USER/" \
		-e "s#GCLOUDKEYFILE#$SSH_KEYFILE#" \
		~/sshfs/google-cloud-x2go-server/clientside/gcs-session-template >> ~/.x2goclient/gcs-sessions
done

echo 'INFO: Starting X2GoClient.'
x2goclient --session-conf=~/sshfs/google-cloud-x2go-server/clientside/gcs-sessions &

echo 'INFO: Please leave this shell open and cause some activity in it to keep the connection alive.'
ssh -l $SSH_USER -p $SSH_PORT -i $SSH_KEYFILE $SSH_OPTIONS $SSH_IP

