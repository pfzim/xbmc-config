#!/bin/sh
# script for remove old backup files v0.01   pfzim (c) 2010 (44f5709e242b975305161941b30d1573)
# First files (sort by name) if free space less that defined
# File name template: backup-YYYY-MM-DD-HHMMSS-*


storage_path='/var/motion'
storage_minspace=30000000000
expired_cmd='rm -f'

awkcmd='awk'

echo 'Script for remove old backup files if free space less v0.01   pfzim (c) 2010'

for filename in `find ${storage_path} -type f -name 'backup-*' -print | sort`; do
	free_space=`df --output=avail --block-size=1 ${storage_path} | tail --lines=1`
	#echo "Free space: ${free_space}"
	#echo "Min space : ${storage_minspace}"
	if [ ${free_space} -ge ${storage_minspace} ] ; then
    	exit 0
	fi

	#filename=`basename $filename`
	filename=`echo $filename | ${awkcmd} -F/ '{ print $NF; }'`
	echo "Deleting file: $filename"

	${expired_cmd} "${storage_path}/${filename}"
done
