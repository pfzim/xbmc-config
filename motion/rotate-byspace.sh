#!/bin/sh
# script for remove old backup files v0.01   pfzim (c) 2010 (44f5709e242b975305161941b30d1573)
# First files (sort by name) if free space less that defined
# File name template: backup-YYYY-MM-DD-HHMMSS-*


storage_path=''
storage_minspace=0
expired_cmd='rm -f'

awkcmd='awk'

while [ $# -gt 0 ]; do
  key="$1"

  case $key in
    -p|--path)
      storage_path="$2"
      shift
      shift
      ;;
    -s|--space)
      ((storage_minspace=$2 * 1073741824))
      shift
      shift
      ;;
    -h|--help)
      storage_minspace=0
      break
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
    ;;
  esac
done


echo 'Script for remove old backup files if free space less v0.02   pfzim (c) 2010'

if [ -z "${storage_path}" -o -z "${storage_minspace}" -o "${storage_minspace}" -le 0 ] ; then
  echo 'Usage: rotate.sh -p /var/backups -s 30'
  echo 'Options:'
  echo '  -p|--path          - path to stored backups'
  echo '  -s|--space         - free space required (GB)'
  echo '  -h|--help          - this help'
  exit 1
fi

#echo "Path : ${storage_path}"
#echo "Min space : ${storage_minspace}"

for full_filename in `find ${storage_path} -type f -name 'backup-*' -print | sort`; do
	free_space=`df --output=avail --block-size=1 ${storage_path} | tail --lines=1`
	#echo "Free space: ${free_space}"
	#echo "Min space : ${storage_minspace}"
	if [ ${free_space} -ge ${storage_minspace} ] ; then
    	exit 0
	fi

	#filename=`basename $filename`
	filename=`echo $full_filename | ${awkcmd} -F/ '{ print $NF; }'`
	echo "Deleting file: $filename"

	${expired_cmd} "${full_filename}"
done

exit 0

