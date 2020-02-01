################################################################################
# fotoBkup.sh - check whather AnaNAZ photo folder is ready for sync and starts #
#		rsync from external disk to NAS			               #
#								               #
# Rev. 0: create this script						       #
################################################################################

#!/bin/sh

HOSTS="192.168.0.3"
MOUNTPOINT='/Volumes/foto'
LOG='/Users/paolomorgano/scripts/log/fotoBkup.log'
LOCK_DIR='/Users/paolomorgano/scripts/log/'
LOCK_NAME='fotoBkup.lock'
LOCK=$(echo $LOCK_DIR$LOCK_NAME)

c_PING_ATTEMPTS=3

/bin/echo "Script starts @ $(date)" > $LOG

# Only run if not already started, checking lock file

if [ -e $LOCK ];
then
	if test $(/usr/bin/find $LOCK_DIR -name $LOCK_NAME  -newerct '7 days ago')
	then
		exit 0
	else
		/bin/rm $LOCK
                /bin/echo "Forcing lock file $LOCK because older than a week" >> $LOG
	fi
fi

touch $LOCK

# First check if NAS is reachable on network

for myHost in $HOSTS
do

        count=$(/sbin/ping -c $c_PING_ATTEMPTS $myHost | awk -F, '/received/{print $2*1}')
        /bin/echo "NAS successful pings $count" >> $LOG

	if [ $count -lt $c_PING_ATTEMPTS ];
	then
		/bin/rm $LOCK
		exit $(3-$count)
	fi

done

# Check if directory is mounted

MOUNT=$(/sbin/mount | grep $MOUNTPOINT)

if [ ${#MOUNT} -le 1 ]
then
	/bin/echo "Unable to find mounpoint $MOUNTPOINT, exit script" >> $LOG
	/bin/rm $LOCK
	exit 100
else
	/bin/echo "Mountpoint: $MOUNT" >> $LOG
fi

# Last cjeck if destination directory is empty

if [ "$(/bin/ls -A $MOUNTPOINT)" ];
then
	/bin/echo "Dir $MOUNTPOINT is not empty"  >>  $LOG
else		
	/bin/echo "Dir $MOUNTPOINT is empty, exit script"  >>  $LOG
	/bin/rm $LOCK
 	exit 200
fi

# Lauch backup
/usr/bin/rsync --verbose  --recursive  --times --modify-window=1 --log-file=$LOG /Volumes/Discobolo/foto/* $MOUNTPOINT >> $LOG

# Remove lock file
/bin/rm $LOCK

# Bye bye
/bin/echo "Script ends @ $(date)" >> $LOG

exit 0

