#!/bin/sh
# script for move files to dated subfolders v0.01   pfzim (c) 2010 (44f5709e242b975305161941b30d1573)
# File name template: backup-YYYY-MM-DD-HHMMSS-*

src_path=''
dst_path=''

awkcmd='awk'

while [ $# -gt 0 ]; do
  key="$1"

  case $key in
    -s|--src)
      src_path="$2"
      shift
      shift
      ;;
    -d|--dst)
      dst_path="$2"
      shift
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
    ;;
  esac
done


echo 'Script for move files to dated subfolders   pfzim (c) 2021'

if [ -z "${src_path}" -o -z "${dst_path}" ] ; then
  echo 'Usage: rotate.sh -s /var/backups -d /var/backups/bydates'
  echo 'Options:'
  echo '  -s|--src           - path to source'
  echo '  -d|--dst           - path to destination'
  echo '  -h|--help          - this help'
  exit 1
fi

curdate=`date '+%Y-%m-%d-%H-%M-%S'`
#curdate=`mysql -h 127.0.0.1 -u LOGIN -pPASSWORD -s --skip-column-names -e "SELECT DATE_FORMAT(NOW(), '%Y-%m-%d-%H-%i-%S');"`

year=`echo $curdate | ${awkcmd} -F- '{ print $1+0; }'`
month=`echo $curdate | ${awkcmd} -F- '{ print $2+0; }'`
day=`echo $curdate | ${awkcmd} -F- '{ print $3+0; }'`

#echo "Path : ${storage_path}"
#echo "Min space : ${storage_minspace}"

for full_filename in `find ${src_path} -maxdepth 1 -type f -iname 'backup-*' -print | sort`; do
    #echo "Free space: ${free_space}"
    #echo "Min space : ${storage_minspace}"
    #filename=`basename $filename`
    filename=`echo $full_filename | ${awkcmd} -F/ '{ print $NF; }'`

    y=`echo $filename | ${awkcmd} -F- '{ print $2+0; }'`
    m=`echo $filename | ${awkcmd} -F- '{ print $3+0; }'`
    d=`echo $filename | ${awkcmd} -F- '{ print $4+0; }'`

    if [ \( "$d" -lt 1 \) -o \( "$d" -gt 31 \) -o \( "$y" -lt 1 \) ] ; then
        echo " : invalid date in file name"
        continue
    fi

    if [ \( "$d" -eq "$day" \) -a \( "$m" -eq "$month" \) -a \( "$y" -eq "$year" \) ] ; then
	continue
    fi

    dst_dir=`printf "%s/%04d-%02d-%02d" "${dst_path}" "${y}" "${m}" "${d}"`

    if [ ! -d "${dst_dir}" ] ; then
      mkdir -p "${dst_dir}"
    fi

    mv -f "${full_filename}" "${dst_dir}/"
done

exit 0
