#!/bin/sh

# Boot XBMCbuntu, CTRL+F1, login and run:
# wget https://raw.githubusercontent.com/pfzim/xbmc-config/master/i.sh
# chmod a+rx i.sh
# sudo ./i.sh

# --wget http://hencvik.googlecode.com/files/i.sh
# --./i.sh 2>&1 | tee i.log

back_title="XBMC 13.2 post installation configuration script v0.08.22 (c) pfzim"
fg_title="XBMC configuration"
DIALOG=whiptail
idir=$(pwd)
dm=openbox

ask() {
  while :
  do
    read -p "$1" $2
    if [ -n "$(eval "echo \$$2")" ] ; then
      break
    fi
    if [ $# -gt 2 -a -n "$3" ] ; then
      eval "$2=\$3"
      break
    fi
  done
}

a_msgbox() {
  ${DIALOG} --backtitle "${back_title}" --clear --title "${fg_title}" --msgbox "$1" 10 75
}

# text result default
a_yesno() {
  defval=" --defaultno"
  if [ "$3" = "yes" ] ; then
    defval=""
  fi

  ${DIALOG} --backtitle "${back_title}" --clear --title "${fg_title}"${defval} --yesno "$1" 22 75
  if [ $? -eq 0 ] ; then
    eval "$2=Y"
  else
    eval "$2=N"
  fi
}

# text result=default value
a_input() {
  temp_result=`mktemp 2>/dev/null` || temp_result=/tmp/test$$
  eval "${DIALOG} --backtitle \"${back_title}\" --clear --title \"${fg_title}\"${defval} --inputbox \"$1\" 10 75 \"\${$2}\" 2>$temp_result"
  result=`cat $temp_result`
  rm -f $temp_result
  if [ $? -eq 0 ] ; then
    eval "$2=\$result"
  fi
}

# text result
a_passwd0() {
  temp_result=`mktemp 2>/dev/null` || temp_result=/tmp/test$$
  ${DIALOG} --backtitle "${back_title}" --clear --title "${fg_title}"${defval} --passwordbox "$1" 10 75 2>$temp_result
  result=`cat $temp_result`
  rm -f $temp_result
  if [ $? -eq 0 ] ; then
    eval "$2=\$result"
  else
    eval "$2=\"$3\""
  fi
}

a_passwd() {
  while :
  do
    temp_passwd1=""
    temp_passwd2=""
    a_passwd0 "$1" temp_passwd1
    a_passwd0 "Enter password again:" temp_passwd2
    if [ -n "$temp_passwd1" -a "$temp_passwd1" = "$temp_passwd2" ] ; then
      eval "$2=\"$temp_passwd1\""
      break
    fi
  done
}

if [ "$(id -u)" != "0" ]; then
  echo "Sorry, you must execute me with sudo."
  exit 1
fi

[ -d xbmc_install ] || mkdir xbmc_install
cd xbmc_install

# backup
curdate=`date '+%Y-%m-%d-%H-%M%S'`
crontab -u xbmc -l > .crontab
tar -czpf backup-${curdate}-pfzim-xbmc.tar.gz --ignore-failed-read .crontab \
  /etc/asound.conf \
  /etc/default/rcS \
  /etc/fstab \
  /etc/iptables.up.rules \
  /etc/minidlna.conf \
  /etc/modules \
  /etc/network/interfaces \
  /etc/rc.local \
  /etc/fonts/local.conf \
  /etc/init.d/rtorrent.sh \
  /etc/modprobe.d/alsa-base.conf \
  /etc/modprobe.d/v4l2loopback.conf \
  /etc/motion/motion.conf \
  /etc/transmission-daemon/settings.json \
  /etc/NetworkManager/NetworkManager.conf \
  /var/www/rutorrent/conf/config.php \
  /usr/lib/X11/xorg.conf.d \
  /usr/share/alsa/cards/HDA-Intel.conf \
  /usr/share/X11/xorg.conf.d \
  /home/rtorrent/.rtorrent.rc \
  /home/xbmc/.asoundrc \
  /home/xbmc/.fdm.conf \
  /home/xbmc/.msmtprc \
  /home/xbmc/scripts/brasero.sh \
  /home/xbmc/scripts/firefox.sh \
  /home/xbmc/scripts/chrome.sh \
  /home/xbmc/.xbmc/userdata/advancedsettings.xml \
  /home/xbmc/.xbmc/userdata/guisettings.xml \
  /home/xbmc/.xbmc/userdata/LCD.xml \
  /home/xbmc/.xbmc/userdata/profiles.xml \
  /home/xbmc/.xbmc/userdata/sources.xml \
  /home/xbmc/.xbmc/userdata/RssFeeds.xml


[ -f xbmc-pfz-0.08.tar.bz2 ] || wget "http://hencvik.googlecode.com/files/xbmc-pfz-0.08.tar.bz2"
tar -xjvf xbmc-pfz-0.08.tar.bz2


# set hardware clock to localtime
############################

#read -p "Set timezone to Europe/Moscow [Y/n]?" result
c_tz() {
  echo "Europe/Moscow" > /etc/timezone
  sed -i -e "s/^\(\\s*UTC\\s*=\\s*\)yes\(\\s*\)\$/\\1no\\2/" /etc/default/rcS
  rm -f /etc/localtime
  ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
  #hwclock --systohc
}

# configure wireless network
############################

#read -p "Install Atheros firmware (ar9271.fw, htc_9271.fw) [y/N]?" result
i_fmw_pre() {
  #[ -f xbmc-firmwares-0.08.tar.bz2 ] || wget "http://pfzim.zh-shop.ru/_xbmc/xbmc-firmwares-0.08.tar.bz2"
  #tar -xjvf xbmc-firmwares-0.08.tar.bz2

  #http://git.kernel.org/?p=linux/kernel/git/dwmw2/linux-firmware.git;a=tree
  [ -f htc_9271.fw ] || wget "http://git.kernel.org/?p=linux/kernel/git/dwmw2/linux-firmware.git;a=blob_plain;f=htc_9271.fw;hb=HEAD"
  [ -f htc_7010.fw ] || wget "http://git.kernel.org/?p=linux/kernel/git/dwmw2/linux-firmware.git;a=blob_plain;f=htc_7010.fw;hb=HEAD"

  #[ -f /lib/firmware/ar9271.fw ] || cp ar9271.fw /lib/firmware/
  [ -f /lib/firmware/htc_9271.fw ] || cp htc_9271.fw /lib/firmware/
  [ -f /lib/firmware/htc_7010.fw ] || cp htc_7010.fw /lib/firmware/
}

#read -p "Install compat-wireless-3.2-rc1-1 from source [y/N]?" result
i_cw_pre() {
  #[ -f compat-wireless-2.6.tar.bz2 ] || wget "http://pfzim.zh-shop.ru/_xbmc/compat-wireless-2.6.tar.bz2"
  #tar -xjvf compat-wireless-2.6.tar.bz2
  [ -f compat-wireless-3.2-rc1-1.tar.bz2 ] || wget "http://www.orbit-lab.org/kernel/compat-wireless-3-stable/v3.2/compat-wireless-3.2-rc1-1.tar.bz2"
  tar -xjvf compat-wireless-3.2-rc1-1.tar.bz2

  cd compat-wireless-*/

  make && make install
  make unload

  cd ..

  #rm -rf /lib/modules/updates/compat*
  depmod
  modprobe ath9k_htc
}

ask_settings_ip() {
  while :
  do
    a_input "Enter IP address [192.168.1.100]:" $1
    a_input "Enter network mask [255.255.255.0]:" $2
    a_input "Enter gateway [192.168.1.1]:" $3
    a_input "Enter DNS1 []:" $4
    a_input "Enter DNS2 []:" $5

    eval "a_yesno \"Network settings:\\n\\nIP: \$$1\nMask: \$$2\\nGateway: \$$3\\nDNS1: \$$4\\nDNS2: \$$5\\n\\nEntered data correct?\" result"
    if [ "$result" = "Y" -o "$result" = "y" ] ; then
      break
    fi
  done
}

ask_settings_pass() {
  while :
  do
    #read -s -p "Enter WPA password: " p1
    #read -s -p "Enter again: " p2
    #read -p "Enter WPA password: " p1
    #read -p "Enter again: " p2
    a_passwd "Enter password for wireless network:" p1

    if [ "${#p1}" -ge 8 -a "${#p1}" -le 63 ] ; then
      eval "$1=$p1"
      break
    else
      a_msgbox "Passphrase must be 8..63 characters"
    fi
  done
}

#read -p "Configure wireless interface [Y/n]?" result
c_wifi_pre() {
  #sudo apt-get install wpasupplicant

  fg_title="Wireless network configuration"

  while :
  do
    list_items=$(iwconfig | grep -e "^\\s*[a-zA-Z]\+[0-9]\+" | sed -e "s/^\\s*\([a-zA-Z]\+[0-9]\+\).*\$/\\1/" |
      (
        n=1
        while read line
        do
          echo "\"${line}\" \"Wireless interface ${n}\""
          n=$((n+1))
        done
        echo "rescan \"Find new WiFi adapters...\""
        echo "exit \"Finish configuration\""
      )
    )

    if [ -z "${list_items}" ] ; then
      break
    fi

    tempfile=`mktemp 2>/dev/null` || tempfile=/tmp/test$$
    #trap "rm -f $tempfile" 0 1 2 5 15

    eval ${DIALOG} --backtitle \"${back_title}\" --clear --title \"Wireless network configuration\" --menu \"Select WiFi inteface\" 20 75 13 ${list_items} 2>$tempfile

    if [ $? -ne 0 ] ; then
      rm -f $tempfile
      break
    fi

    net_if=$(cat $tempfile)
    rm -f $tempfile

    if [ "${net_if}" = "rescan" ] ; then
      continue
    fi

    if [ "${net_if}" = "exit" ] ; then
      break
    fi

    ifconfig ${net_if} up

    list_items=$(iwlist ${net_if} scan 2>&1 | \
    sed -e "s/^\\s*//" \
        -e "s/^Cell [0-9]\+ - /#/" \
        -e "s/^#Address: \([0-9a-Z:]\+\)\$/#ap_mac=\"\\1\"/" \
        -e "s/^Quality=\([0-9]\+\\/[0-9]\+\).*\$/ap_quality=\"\\1\"/" \
        -e "s/^.*Channel \([0-9]\+\).*\$/ap_channel=\\1/" \
        -e "s/^ESSID:/ap_essid=/" \
        -e "s/^Mode: \([a-Z]+\)\$/ap_mode=\\1/" \
        -e "s/^Encryption key:\([a-Z]\+\)\$/ap_enc=\\1/" \
        -e "s/^IE: WPA Version \([0-9]\+\)\$/ap_etype=WPA\nap_ever=\\1/" | \
    grep "^#\?ap_[a-z]\+=.*$" | \
    tr "\n#" ";\n" | \
    grep -v "^\$" | \
    sed -e "s/;\$//" | \
    sed -e "s/\"/\\\"/" | \
    awk "{ print NR \";\" \$0 }"
      )
    list_menu=$(echo "${list_items}" | sed -e "s/^\([0-9]\+\).*ap_essid=\([^;]\+\).*\$/\1 \2/")

    #echo "*** RESULT ***"
    #echo "${list_items}"
    #echo "*** RESULT ***"
    #echo "*** RESULT ***"
    #echo "${list_menu}"
    #echo "*** RESULT ***"

    if [ -n "${list_items}" ] ; then
      eval ${DIALOG} --backtitle \"${back_title}\" --clear --title \"Wireless network configuration\" --menu \"Select WiFi accesspoint\" 20 75 13 ${list_menu} 2>$tempfile

      if [ $? -eq 0 ] ; then
        sel_item=$(cat $tempfile)
        ap_info=$(echo "${list_items}" | grep "^${sel_item};" | sed -e "s/^[0-9]\+;//")
        #echo "AP_INFO: ${ap_info}"
        eval "${ap_info}"
        #echo "MAC: ${ap_mac}"
        #echo "ESSID: ${ap_essid}"
        #echo "ENC-TYPE: ${ap_etype}"

        net_res="# xbmc-config-script-${net_if}\n"
        net_res="${net_res}auto ${net_if}\n"
        net_dhcp=1

        #read -p "Use DHCP [Y/n]?" result
        a_yesno "Use DHCP?" result "yes"
        if [ "$result" = "Y" -o "$result" = "y" ] ; then
          net_res="${net_res}iface ${net_if} inet dhcp\n"
        else
          net_dhcp=0
          net_ip="192.168.1.100"
          net_mask="255.255.255.0"
          net_gw="192.168.1.1"
          net_dns1=""
          net_dns2=""
          ask_settings_ip net_ip net_mask net_gw net_dns1 net_dns2
          net_res="${net_res}iface ${net_if} inet static\n"
          net_res="${net_res}address ${net_ip}\n"
          net_res="${net_res}netmask ${net_mask}\n"
          net_res="${net_res}gateway ${net_gw}\n"
          if [ -n "${net_dns1}" -o -n "${net_dns2}" ] ; then
            net_res="${net_res}dns-nameservers"
            if [ -n "${net_dns1}" ] ; then
              net_res="${net_res} ${net_dns1}"
            fi
            if [ -n "${net_dns2}" ] ; then
              net_res="${net_res} ${net_dns2}\n"
            fi
            net_res="${net_res}\n"
          fi
        fi

        if eval "sed \"/# xbmc-config-script-${net_if}/,/# xbmc-config-script-${net_if}-end/d\" /etc/network/interfaces | grep -v -e \"^\\\\s*#\" | grep -q -e \"${net_if}\"" ; then
          a_msgbox "Error: configuration for interface ${net_if} already exist in file /etc/network/interfaces"
        else
          if [ "${ap_enc}" = "on" ]  ; then
            ask_settings_pass ap_pass

            if [ "${ap_etype}" = "WPA" ]  ; then
              ap_pass=$(wpa_passphrase "${ap_essid}" "${ap_pass}" | grep "^\s*psk=" | sed -e "s/^\s*psk=\(.*\)$/\1/")

              net_res="${net_res}wpa-driver wext\n"
              net_res="${net_res}wpa-ssid ${ap_essid}\n"
              net_res="${net_res}wpa-ap-scan 2\n"
              net_res="${net_res}wpa-proto RSN WPA\n"
              net_res="${net_res}wpa-pairwise CCMP TKIP\n"
              net_res="${net_res}wpa-group CCMP TKIP\n"
              net_res="${net_res}wpa-key-mgmt WPA-PSK\n"
              net_res="${net_res}wpa-psk ${ap_pass}\n"
            else
              # WEP
              net_res="${net_res}wireless-mode managed\n"
              net_res="${net_res}wireless-essid ${ap_essid}\n"
              net_res="${net_res}wireless-enc ${ap_pass}\n"
            fi
          else
              net_res="${net_res}wireless-mode managed\n"
              net_res="${net_res}wireless-essid ${ap_essid}\n"
          fi

          net_res="${net_res}# xbmc-config-script-${net_if}-end\n"

          #echo "\n${net_res}"

          #read -p "Save this configuration [Y/n]?" result
          a_yesno "${net_res}\nSave this configuration?" result "yes"
          if [ "$result" = "Y" -o "$result" = "y" ] ; then
            sed -i "/# xbmc-config-script-${net_if}/,/# xbmc-config-script-${net_if}-end/d" /etc/network/interfaces
            echo "${net_res}" >> /etc/network/interfaces
          fi

          a_yesno "${net_res}\nConnect NOW using this configuration?" result "yes"
          if [ "$result" = "Y" -o "$result" = "y" ] ; then
            if [ "${ap_enc}" = "on" ]  ; then
              if [ "${ap_etype}" = "WPA" ]  ; then
                tempconf=`mktemp 2>/dev/null` || tempconf=/tmp/test$$
                wpa_passphrase "${ap_essid}" "${ap_pass}" > tempconf
                wpa_supplicant -Dwext -i${net_if} -c${tempconf}
                rm -f ${tempconf}
              else
                iwconfig ${net_if} essid "${ap_essid}" key "${ap_pass}"
              fi
            else
              iwconfig ${net_if} essid "${ap_essid}"
            fi

            if [ "$net_dhcp" -eq 1 ] ; then
              dhclient ${net_if}
            else
              ifconfig ${net_if} inet ${net_if} netmask ${net_mask}
              route add default gw ${net_gw} ${net_if}
            fi
          fi

        fi

      fi
      rm -f $tempfile

    fi

  done
}

# update
############################

#read -p "Update aptitude (apt-get update) [Y/n]?" result
i_aptup() {
  # Webmin repository
  #deb http://download.webmin.com/download/repository sarge contrib
  #deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib
  #wget http://www.webmin.com/jcameron-key.asc
  #apt-key add jcameron-key.asc

  #chromium repository
  #add-apt-repository ppa:chromium-daily/ppa

  add-apt-repository -y ppa:transmissionbt/ppa

  apt-get -y update
}

# install NetworkManager
############################

#read -p "Install Network Manager [Y/n]?" result
i_nm() {
  apt-get -y install network-manager
  sed -i "s/\(\\s*managed\\s*=\\s*\)false/\\1true/" /etc/NetworkManager/NetworkManager.conf
  #echo "\nnm-applet --sm-disable &" >> ~/.fluxbox/startup
}

# configure DDNS
############################

ask_settings_noip() {
  while :
  do
    #echo "DDNS no-ip.com settings:"
    a_input "Enter login: " $1
    a_passwd "Enter password: " $2
    a_input "Enter host: " $3

    eval "a_yesno \"no-ip.com DDNS service settings:\\n\\nLogin: \$$1\\nPassword: *hidden*\\nHost: \$$3\\n\\nEntered data correct?\" result \"yes\""
    if [ "$result" = "Y" -o "$result" = "y" ] ; then
      break
    fi
  done
}

#read -p "Configure DDNS no-ip.com script [Y/n]?" result
c_ddns_pre() {
  noip_user=""
  noip_passwd=""
  noip_host="youname.no-ip.org"

  fg_title="DDNS no-ip.com settings"
  ask_settings_noip noip_user noip_passwd noip_host
}

c_ddns() {
  crontab -u xbmc -l > .crontab
  cat >> .crontab << EOF
*/15 * * * * wget --quiet --delete-after --auth-no-challenge --user="${noip_user}" --password="${noip_passwd}" --user-agent="wget based script/0.01 pfzim@mail.ru" "http://dynupdate.no-ip.com/nic/update?hostname=${noip_host}"
EOF
  crontab -u xbmc .crontab
}

# install Midnight commander
############################

#read -p "Install Midnight commander [Y/n]?" result
i_mc() {
  apt-get -y install mc man
}

# configure HDMI audio
############################

#read -p "Configure HDMI audio (run only if HDMI audio does not work) [y/N]?" result
c_hdmi() {
  hdmi_device=`aplay -l | grep HDMI | sed -e "s/^card \([0-9]\):.*device \([0-9]\):.*\$/\\1,\\2/"`

  if [ -n "${hdmi_device}" ] ; then
    # sed -e "s/\$hdmi_device/${hdmi_device}/" asound.conf > /etc/asound.conf
    # sed -e "s/\$hdmi_device/${hdmi_device}/" .asoundrc > /home/xbmc/.asoundrc

    [ -f /etc/asound.conf ] || cat > /etc/asound.conf << EOF
pcm.!hdmi-remap {
  type asym
  playback.pcm {
    type plug
    slave.pcm "remap-surround71"
  }
}

pcm.!remap-surround71 {
  type route
  slave.pcm "hw:${hdmi_device}"
  ttable {
    0.0= 1
    1.1= 1
    2.4= 1
    3.5= 1
    4.2= 1
    5.3= 1
    6.6= 1
    7.7= 1
  }
}
EOF

    [ -f /home/xbmc/.asoundrc ] || cat > /home/xbmc/.asoundrc << EOF
pcm.dmixer {
  type dmix
  ipc_key 1024
  ipc_key_add_uid false
  ipc_perm 0660
  slave {
    pcm "hw:${hdmi_device}"
    #pcm "ladcomp"
    rate 48000
    channels 2
    format S32_LE
    period_time 0
    period_size 1024
    buffer_time 0
    buffer_size 4096
  }
}

pcm.!default {
  type plug
  slave.pcm "dmixer"
}
EOF

    cat /etc/modprobe.d/alsa-base.conf | grep -q -e "^\\s*options\\s*snd-hda-intel\\s*model=6stack-dig\\s*\$" || cat >>  /etc/modprobe.d/alsa-base.conf << EOF

# Audio over HDMI
options snd-hda-intel model=6stack-dig
EOF

    [ -f /usr/share/alsa/cards/HDA-Intel.conf.org ] || mv /usr/share/alsa/cards/HDA-Intel.conf /usr/share/alsa/cards/HDA-Intel.conf.org
    cp HDA-Intel.conf /usr/share/alsa/cards/

    hdmi_card=`echo ${hdmi_device} | awk -F, '{ print $1; }'`
    /usr/bin/amixer -q -c ${hdmi_card} sset 'Master',0 unmute && /usr/bin/amixer -q -c ${hdmi_card} sset 'Master',0 100
    /usr/bin/amixer -q -c ${hdmi_card} sset 'IEC958 Default PCM',${hdmi_card} unmute
    /usr/bin/amixer -q -c ${hdmi_card} sset 'IEC958',0 unmute && /usr/bin/amixer -q -c ${hdmi_card} sset 'IEC958',1 unmute
    alsactl store ${hdmi_card}

    # speaker-test -D hdmi -c6 -r19200 -FS32_LE
  fi
}

#read -p "Install audio Normalization (Dynamic Range Compression) plugin [Y/n]?" result
i_drc() {
  apt-get -y install swh-plugins
  hdmi_device=`aplay -l | grep HDMI | sed -e "s/^card \([0-9]\):.*device \([0-9]\):.*\$/\\1,\\2/"`

  if [ -n "${hdmi_device}" ] ; then
    cat /home/xbmc/.asoundrc | grep -q -e "pcm\\.drc" || cat >> /home/xbmc/.asoundrc << EOF

pcm.drc {
  type plug
  slave.pcm "drc_compressor";
}

pcm.drc_compressor {
  type ladspa
  slave.pcm "drc_limiter";
  path "/usr/lib/ladspa";
  plugins [
    {
      label dysonCompress
      input {
        #peak limit, release time, fast ratio, ratio
        controls [0 1 0.5 0.99]
      }
    }
  ]
}

pcm.drc_limiter {
  type ladspa
  slave.pcm "plughw:${hdmi_device}";
  path "/usr/lib/ladspa";
  plugins [
    {
      label fastLookaheadLimiter
      input {
        #InputGain(Db) -20 -> +20 ; Limit (db) -20 -> 0 ; Release time (s) 0.01 -> 2
        controls [ 20 0 0.8  ]
      }
    }
  ]
}
EOF
  fi
}

# install xbmc plugins
############################

#read -p "Install XBMC plugins (Advanced Launcher) [Y/n]?" result
i_plugins() {
  #wget http://mirrors.xbmc.org/addons/dharma/plugin.program.executor/plugin.program.executor-0.2.5.zip
  #wget http://mirrors.xbmc.org/addons/dharma/plugin.program.launcher/plugin.program.launcher-1.10.2.zip
  #unzip plugin.program.executor-0.2.5.zip -d /home/xbmc/.xbmc/addons/
  #unzip plugin.program.launcher-1.10.2.zip -d /home/xbmc/.xbmc/addons/

  # Eden
  #wget http://mirrors.xbmc.org/addons/eden/plugin.program.advanced.launcher/plugin.program.advanced.launcher-1.7.6.zip
  #unzip plugin.program.advanced.launcher-1.7.6.zip -d /home/xbmc/.xbmc/addons/
  #wget http://mirrors.xbmc.org/addons/eden/skin.confluence-vertical/skin.confluence-vertical-2.1.1.zip
  #unzip skin.confluence-vertical-2.1.1.zip -d /home/xbmc/.xbmc/addons/
  #wget http://mirrors.xbmc.org/addons/eden/plugin.program.rtorrent/plugin.program.rtorrent-1.11.7.zip
  #unzip plugin.program.rtorrent-1.11.7.zip -d /home/xbmc/.xbmc/addons/
  #wget http://mirrors.xbmc.org/addons/eden/script.transmission/script.transmission-0.7.1.zip
  #unzip script.transmission-0.7.1.zip -d /home/xbmc/.xbmc/addons/

  # Frodo
  #wget http://mirrors.xbmc.org/addons/frodo/plugin.program.advanced.launcher/plugin.program.advanced.launcher-1.7.6.zip
  #unzip plugin.program.advanced.launcher-1.7.6.zip -d /home/xbmc/.xbmc/addons/
  wget http://www.gwenael.org/Repository/repository.angelscry.xbmc-plugins/repository.angelscry.xbmc-plugins-1.2.2.zip
  unzip repository.angelscry.xbmc-plugins-1.2.2.zip -d /home/xbmc/.xbmc/addons/
  wget http://www.gwenael.org/Repository/plugin.program.advanced.launcher/plugin.program.advanced.launcher-2.0.10.zip
  unzip plugin.program.advanced.launcher-2.0.10.zip -d /home/xbmc/.xbmc/addons/
  #wget http://mirrors.xbmc.org/addons/eden/skin.confluence-vertical/skin.confluence-vertical-2.1.1.zip
  #unzip skin.confluence-vertical-2.1.1.zip -d /home/xbmc/.xbmc/addons/
  wget http://mirrors.xbmc.org/addons/frodo/plugin.program.rtorrent/plugin.program.rtorrent-1.11.7.zip
  unzip plugin.program.rtorrent-1.11.7.zip -d /home/xbmc/.xbmc/addons/
  wget http://mirrors.xbmc.org/addons/frodo/script.transmission/script.transmission-0.7.1.zip
  unzip script.transmission-0.7.1.zip -d /home/xbmc/.xbmc/addons/

  #wget
  #unzip   -d /home/xbmc/.xbmc/addons/
  #wget
  #unzip   -d /home/xbmc/.xbmc/addons/
}

# install rtorrent
############################

#read -p "Install rtorrent [Y/n]?" result
rtor_src=0
rtorrent_media="/media/torrents/video"
rtorrent_data="/home/rtorrent"

i_rtor_pre() {
  fg_title="rtorrent settings"
  while :
  do
    a_yesno "Build rtorrent from sorce code?" result "no"
    #read -p "Build rtorrent from sorce code [y/N]?" result
    if [ "$result" = "Y" -o "$result" = "y" ] ; then
      rtor_src=1
    fi

    a_input "Enter path where you want save rtorrent download" rtorrent_media
    a_input "Enter path where you want save rtorrent session data" rtorrent_data

    rtorrent_media=`echo ${rtorrent_media} | sed -e "s/\\/*\$//"`
    rtorrent_data=`echo ${rtorrent_data} | sed -e "s/\\/*\$//"`

    a_yesno "rtorrent settings:\n\nDownloads path: ${rtorrent_media}\nSessions path: ${rtorrent_data}\n\nEntered data correct?" result "yes"
    if [ "$result" = "Y" -o "$result" = "y" ] ; then
      break
    fi
  done
}

i_rtor() {
  if [ $rtor_src -eq 1 ] ; then
    apt-get -y install screen build-essential libtool automake libsigc++-2.0-dev libncurses5-dev libcurl4-openssl-dev libxmlrpc-c3-dev
    #?apt-get -y install openssl libncursesw5-dev libcppunit-dev

    wget http://libtorrent.rakshasa.no/downloads/libtorrent-0.12.9.tar.gz
    wget http://libtorrent.rakshasa.no/downloads/rtorrent-0.8.9.tar.gz
    tar -xvzf libtorrent-0.12.9.tar.gz
    tar -xvzf rtorrent-0.8.9.tar.gz

    cd libtorrent-*/
    ./autogen.sh
    ./configure --prefix=/usr
    make && make install
    cd ..

    cd rtorrent-*/
    ./autogen.sh
    ./configure --with-xmlrpc-c --prefix=/usr
    make && make install
    cd ..
  else
    apt-get -y install screen rtorrent
  fi

  addgroup rtorrent
  adduser --gecos "" --ingroup rtorrent --disabled-login rtorrent

  [ -d "${rtorrent_data}" ] || mkdir -p "${rtorrent_data}"
  [ -d "${rtorrent_media}" ] || mkdir -p "${rtorrent_media}"
  chmod a+rwx "${rtorrent_media}"
  [ -d "${rtorrent_data}/_control" ] || mkdir "${rtorrent_data}/_control/"
  chmod a+rwx "${rtorrent_data}/_control/"
  [ -d "${rtorrent_data}/_control/audio" ] || mkdir "${rtorrent_data}/_control/audio/"
  chmod a+rwx "${rtorrent_data}/_control/audio/"
  [ -d "${rtorrent_data}/_control/video" ] || mkdir "${rtorrent_data}/_control/video/"
  chmod a+rwx "${rtorrent_data}/_control/video/"

  [ -d "${rtorrent_data}/session" ] || mkdir "${rtorrent_data}/session/"
  chmod a+rx "${rtorrent_data}/session/"
  chown rtorrent:rtorrent "${rtorrent_data}/session/"

  cp rtorrent.sh /etc/init.d/
  chmod a+rx /etc/init.d/rtorrent.sh
  update-rc.d rtorrent.sh defaults

  #[ -f /home/rtorrent/.rtorrent.rc ] || cp rtorrent.rc /home/rtorrent/.rtorrent.rc
  rtorrent_media_esc=`echo ${rtorrent_media} | sed -e "s/\([\\/\\+\\.\\\$]\)/\\\\\\\\\\1/g"`
  [ -f /home/rtorrent/.rtorrent.rc ] || ( sed -e "s/\\\$rtorrent_download/${rtorrent_media_esc}\\/" rtorrent.rc > /home/rtorrent/.rtorrent.rc )
  chmod a+r /home/rtorrent/.rtorrent.rc

  #echo "\nrm -f /home/rtorrent/session/rtorrent.lock" >> /etc/rc.local
  #sed -i "s/^\\s*exit\\s*0\\s*$/\\[ -f \\/home\\/rtorrent\\/session\\/rtorrent\\.lock \] \\&\\& rm -f \\/home\\/rtorrent\\/session\\/rtorrent\\.lock\\n\\nexit 0\\n/" /etc/rc.local
  rtorrent_data_esc=`echo ${rtorrent_data} | sed -e "s/\([\\/\\+\\.\\\$]\)/\\\\\\\\\\1/g"`
  sed -i "s/^\\s*exit\\s*0\\s*\$/\\[ -f ${rtorrent_data_esc}\\/session\\/rtorrent\\.lock \] \\&\\& rm -f ${rtorrent_data_esc}\\/session\\/rtorrent\\.lock\\n\\nexit 0\\n/" /etc/rc.local
}


# install transmission-daemon
##############################

i_tbt_pre() {
  fg_title="transmission-daemon settings (some as rtorrent)"
  while :
  do
    a_input "Enter path where you want save torrent download" rtorrent_media
    a_input "Enter path where you want save torrent session data" rtorrent_data

    rtorrent_media=`echo ${rtorrent_media} | sed -e "s/\\/*\$//"`
    rtorrent_data=`echo ${rtorrent_data} | sed -e "s/\\/*\$//"`

    a_yesno "transmission-daemon settings:\n\nDownloads path: ${rtorrent_media}\nSessions path: ${rtorrent_data}\n\nEntered data correct?" result "yes"
    if [ "$result" = "Y" -o "$result" = "y" ] ; then
      break
    fi
  done
}

i_tbt() {
  apt-get -y install transmission-daemon

  [ -d "${rtorrent_data}" ] || mkdir -p "${rtorrent_data}"
  [ -d "${rtorrent_media}" ] || mkdir -p "${rtorrent_media}"
  chmod a+rwx "${rtorrent_media}"
  [ -d "${rtorrent_data}/_control" ] || mkdir "${rtorrent_data}/_control/"
  chmod a+rwx "${rtorrent_data}/_control/"

  [ -d "${rtorrent_data}/resume" ] || mkdir "${rtorrent_data}/resume/"
  chmod a+rx "${rtorrent_data}/resume/"
  chown -R debian-transmission:debian-transmission "${rtorrent_data}/resume/"

  [ -d "${rtorrent_data}/torrents" ] || mkdir "${rtorrent_data}/torrents/"
  chmod a+rx "${rtorrent_data}/torrents/"
  chown -R debian-transmission:debian-transmission "${rtorrent_data}/torrents/"

  rm -rf /var/lib/transmission-daemon/info/resume
  rm -rf /var/lib/transmission-daemon/info/torrents

  ln -s "${rtorrent_data}/resume/" /var/lib/transmission-daemon/info/resume
  ln -s "${rtorrent_data}/torrents/" /var/lib/transmission-daemon/info/torrents

  rtorrent_media_esc=`echo ${rtorrent_media} | sed -e "s/\([\\/\\+\\.\\\$]\)/\\\\\\\\\\1/g"`
  rtorrent_data_esc=`echo ${rtorrent_data} | sed -e "s/\([\\/\\+\\.\\\$]\)/\\\\\\\\\\1/g"`
  sed -i "s/^\(\\s*{\)/\\1\\n    \"watch-dir\": \"${rtorrent_data_esc}\\/_control\\/\",\\n    \"watch-dir-enabled\": true,/" /etc/transmission-daemon/settings.json
  sed -i "s/\"download-dir\": [^,]*/\"download-dir\": \"${rtorrent_media_esc}\\/\"/" /etc/transmission-daemon/settings.json
  sed -i "s/\"rpc-authentication-required\": [^,]*/\"rpc-authentication-required\": false/" /etc/transmission-daemon/settings.json

  invoke-rc.d transmission-daemon reload
}

# install onboard
############################

#read -p "Install on screen keyboard (onboard) [Y/n]?" result
i_onboard() {
  apt-get -y onboard
}

# install firefox
############################

#read -p "Install firefox [Y/n]?" result
i_ffox() {
  apt-get -y --no-install-recommends install firefox flashplugin-nonfree

  [ -d /home/xbmc/scripts ] || mkdir /home/xbmc/scripts/
  chmod a+rx /home/xbmc/scripts/

  [ -f /home/xbmc/scripts/firefox.sh ] || cat > /home/xbmc/scripts/firefox.sh << EOF
#!/bin/sh

${dm} &
nm-applet --sm-disable &
firefox
killall -9 ${dm}
EOF

  chmod a+rx /home/xbmc/scripts/firefox.sh
}

# install chromium
############################

#read -p "Install chromium browser [Y/n]?" result
i_chrome() {
  apt-get -y install chromium-browser

  [ -d /home/xbmc/scripts ] || mkdir /home/xbmc/scripts/
  chmod a+rx /home/xbmc/scripts/

  [ -f /home/xbmc/scripts/chrome.sh ] || cat > /home/xbmc/scripts/chrome.sh << EOF
#!/bin/sh

${dm} &
nm-applet --sm-disable &
chromium-browser
killall -9 ${dm}
EOF

  chmod a+rx /home/xbmc/scripts/chrome.sh
}

# configure bluetooth
############################

#read -p "Configure bluetooth [Y/n]?" result
c_bluez() {
  apt-get -y install bluez bluez-utils bluez-hcidump python-dbus
  #modprobe hidp
  #cat /etc/modules | grep -q -e "^\\s*hidp\\s*\$" || echo "hidp" >> /etc/modules
  #/etc/init.d/bluetooth restart

  #hci_device="hci0"

  while :
  do

    list_items=$(hciconfig | grep -e "^\\s*[a-zA-Z]\+[0-9]\+" | sed -e "s/^\\s*\([a-zA-Z]\+[0-9]\+\).*\$/\\1/" |
      (
        n=1
        while read line
        do
          echo "\"${line}\" \"Bluetooth interface ${n}\""
          n=$((n+1))
        done
        echo "rescan \"Scan again for bluetooth adapters...\""
      )
    )

    if [ -z "${list_items}" ] ; then
      break
    fi

    tempfile=`mktemp 2>/dev/null` || tempfile=/tmp/test$$
    #trap "rm -f $tempfile" 0 1 2 5 15

    eval ${DIALOG} --backtitle \"${back_title}\" --clear --title \"Bluetooth HID device configuration\" --menu \"Select bluetooth inteface\" 20 75 13 ${list_items} 2>$tempfile

    if [ $? -ne 0 ] ; then
      rm -f $tempfile
      break
    fi

    hci_device=$(cat $tempfile)
    rm -f $tempfile

    if [ "${hci_device}" != "rescan" ] ; then
      #cat >> /var/lib/bluetooth/xx:xx:xx:xx:xx:xx/config << EOF
      #mode connectable
      #modeon connectable
      #discovto 0
      #pairto 0
      #EOF

      hciconfig ${hci_device} up

      #${DIALOG} --backtitle "${back_title}" --clear --title "XBMC configuration" --msgbox "Initialise pairing mode on connected device and press Enter..." 10 75
      a_msgbox "Initialise pairing mode on connected device and press Enter..."
      #read -p "Initialise pairing mode on connected device and press Enter..." result
      echo "\n\nScanning for bluetooth devices...\n"

      list_items=$(hcitool scan | grep -v "^Scanning \\.\\.\\.\$" |
        (
          n=1
          while read line
          do
            #echo "${n} \"${line}\""
            echo $line | sed -e "s/^\\s*\([^ ]\+\)\\s\+\(.*\)\$/\"\\1\" \"\\2\"/"
            n=$((n+1))
          done
        )
      )

      if [ -n "${list_items}" ] ; then

        tempfile=`mktemp 2>/dev/null` || tempfile=/tmp/test$$

        eval ${DIALOG} --backtitle \"${back_title}\" --clear --title \"Bluetooth HID device configuration\" --menu \"Select HID device\" 20 75 13 ${list_items} 2>$tempfile

        if [ $? -eq 0 ] ; then
          dev_addr=$(cat $tempfile)

          if [ "${dev_addr}" != "rescan" ] ; then
            if [ -f /usr/share/doc/bluez/examples/simple-agent ] ; then
              /usr/share/doc/bluez/examples/simple-agent ${hci_device} ${dev_addr}
            else
              bluez-simple-agent ${hci_device} ${dev_addr}
            fi

            if [ -f /usr/share/doc/bluez/examples/test-device ] ; then
              /usr/share/doc/bluez/examples/test-device trusted ${dev_addr} yes
            else
              bluez-test-device trusted ${dev_addr} yes
            fi

            if [ -f /usr/share/doc/bluez/examples/test-input ] ; then
              /usr/share/doc/bluez/examples/test-input connect ${dev_addr}
            else
              bluez-test-input connect ${dev_addr}
            fi
          fi
        fi

        rm -f $tempfile
      fi
    fi
  done
}

# configure console
############################

#read -p "Install cyrillic for console [Y/n]?" result
i_cyrillic() {
  apt-get -y install console-data
  apt-get -y install console-cyrillic
}


# install apache
############################

#read -p "Install HTTP server Apache2 [Y/n]?" result
i_httpd() {
  apt-get -y install apache2 libapache2-mod-php5
}

# install proftpd
############################

#read -p "Install FTP server ProFTPd [Y/n]?" result
i_ftpd() {
  apt-get -y install proftpd
}

# install rutorrent
############################

#read -p "Install web-interface for rtorrent (rutorrent) [Y/n]?" result
i_rutor() {
  wget http://rutorrent.googlecode.com/files/rutorrent-3.3.tar.gz
  wget http://rutorrent.googlecode.com/files/plugins-3.3.tar.gz
  tar -xzvf rutorrent-3.3.tar.gz -C /var/www/
  tar -xzvf plugins-3.3.tar.gz -C /var/www/rutorrent/
  chown -R root:www-data /var/www/rutorrent
  chmod -R g+w /var/www/rutorrent
  sed -i -e "s/^\(\\s*\\\$scgi_port\\s*=\\s*\)[0-9]\+\(\\s*;\\s*\)\$/\\15001\\2/" /var/www/rutorrent/conf/config.php
  cat > /var/www/rutorrent/plugins/diskspace/action.php << EOF
<?php
	require_once( '../../php/util.php' );
	require_once( '../../php/xmlrpc.php' );

	\$req = new rXMLRPCRequest( new rXMLRPCCommand('get_directory') );
	if(\$req->success())
	{
		\$dir=\$req->val[0];
	}
	else
	{
		\$dir=\$topDirectory;
	}
	
	cachedEcho('{ "total": '.disk_total_space(\$dir).', "free": '.disk_free_space(\$dir).' }',"application/json");
?>
EOF

}

# install webmin
############################

#read -p "Install Webmin [Y/n]?" result
i_webmin() {
  #apt-get -y install webmin

  apt-get -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
  #wget http://prdownloads.sourceforge.net/webadmin/webmin_1.580_all.deb
  #dpkg --install webmin_1.580_all.deb
  wget -O webmin-current.deb http://www.webmin.com/download/deb/webmin-current.deb
  dpkg --install webmin-current.deb
  apt-get -fy install
}

# install iptables
############################

i_frw() {
  iptables -A PREROUTING -t mangle -p tcp --sport 0:1024 -j TOS --set-tos Minimize-Delay
  iptables -A PREROUTING -t mangle -p tcp --sport 1025:65535 -j TOS --set-tos Maximize-Throughput
  iptables -A OUTPUT -t mangle -p tcp --dport 0:1024 -j TOS --set-tos Minimize-Delay
  iptables -A OUTPUT -t mangle -p tcp --dport 1025:65535 -j TOS --set-tos Maximize-Throughput

  iptables-save > /etc/iptables.up.rules
  if ! eval "cat /etc/network/interfaces | grep -v -e \"^\\\\s*#\" | grep -q -e \"/etc/iptables.up.rules\"" ; then
    sed -i "/iface\\s*lo/a\\\\tpost-up iptables-restore < /etc/iptables.up.rules" /etc/network/interfaces
  fi
}
# install rtorrent control through mail
############################

pop3_server="pop.yandex.ru"
pop3_port="995"
pop3_login=""
pop3_passwd=""

smtp_server="smtp.yandex.ru"
smtp_port="587"
smtp_mail="username@yandex.ru"
smtp_login=""
smtp_passwd=""

ask_settings_fdm() {
  while :
  do
    #echo "Mailbox for receive remote commands configuration:"
    a_input "Enter POP3S server address [pop.yandex.ru]: " $1
    a_input "Enter POP3S server port [995]: " $2
    a_input "Enter login for POP3S (user): " $3
    a_passwd "Enter password for POP3S: " $4

    eval "a_yesno \"Mailbox for receive remote commands configuration:\\nServer: \$$1\\nPort: \$$2\\nLogin: \$$3\\nPassword: *hidden*\\n\\nEntered data correct?\" result \"yes\""
    if [ "$result" = "Y" -o "$result" = "y" ] ; then
      break
    fi
  done
}

ask_settings_msmtp() {
  while :
  do
    #echo "Sendmail settings:"
    a_input "Enter SMTP server address [smtp.yandex.ru]: " $1
    a_input "Enter SMTP server port [465]: " $2
    a_input "Enter mail address for SMTP (username@yandex.ru): " $5
    a_input "Enter login for SMTP (username): " $3
    a_passwd "Enter password for SMTP: " $4

    eval "a_yesno \"Sendmail settings:\\nServer: \$$1\\nPort: \$$2\\nMail: \$$5\\nLogin: \$$3\\nPassword: *hidden*\\n\\nEntered data correct?\" result \"yes\""
    if [ "$result" = "Y" -o "$result" = "y" ] ; then
      break
    fi
  done
}

#read -p "Install rtorrent control through mail [Y/n]?" result
i_fdm_pre() {
  fg_title="FDM settings for remote control through mail (POP3/SMTP)"
  ask_settings_fdm pop3_server pop3_port pop3_login pop3_passwd
  ask_settings_msmtp smtp_server smtp_port smtp_login smtp_passwd smtp_mail
}

i_fdm() {
  apt-get -y install fdm msmtp mpack heirloom-mailx

  #ask_settings_fdm pop3_server pop3_port pop3_login pop3_passwd
  [ -f /home/xbmc/scripts/control-reply.sh ] || cat > /home/xbmc/scripts/control-reply.sh << EOF
#! /bin/sh
 
if [ "$#" -ne 1 ] ; then
  exit 1
fi

from=`sed -e "/^.$/q" | grep "^From:" | sed -n -e "s/^From: [^<]*<\(.*\)>$/\1/p;s/^From: \([^<>]\+\)$/\1/p" | head -n 1`
 
if [ -n "\${from}" ] ; then
  echo ${from} | grep -qi "^${smtp_mail}"
  if [ $? -ne 0 ] ; then
    from="${smtp_mail},\${from}"
  fi
else
  from="${smtp_mail}"
fi
 
eval "($1) | mailx -s \"Operation result\" \"\${from}\""
EOF

  chmod 600 /home/xbmc/scripts/control-reply.sh
  chown xbmc:xbmc /home/xbmc/scripts/control-reply.sh

  [ -f /home/xbmc/.fdm.conf ] || cat > /home/xbmc/.fdm.conf << EOF
set maximum-size      10M
set delete-oversized
set queue-high        1
set queue-low         0
set purge-after       10
set unmatched-mail    keep

action "drop" drop
action "keep" keep

action "inbox" maildir "%h/Mail/INBOX"
action "rtorrent-add" pipe "munpack -f -q -C ${rtorrent_data}/_control/ ; for i in ${rtorrent_data}/_control/*.torrent ; do chmod a+r \$i ; done"
action "rtorrent-add-audio" pipe "munpack -f -q -C ${rtorrent_data}/_control/audio/ ; for i in ${rtorrent_data}/_control/audio/*.torrent ; do chmod a+r \$i ; done"
action "rtorrent-add-video" pipe "munpack -f -q -C ${rtorrent_data}/_control/video/ ; for i in ${rtorrent_data}/_control/video/*.torrent ; do chmod a+r \$i ; done"
action "rtorrent-list" pipe "/home/xbmc/scripts/control-reply.sh \"df -h ; transmission-remote -si -st -l\""
action "rtorrent-alt-on" exec "transmission-remote --alt-speed"
action "rtorrent-alt-off" exec "transmission-remote --no-alt-speed"

account "xbmc"
        pop3s
        server   "${pop3_server}"
        port     ${pop3_port}
        user     "${pop3_login}"
        pass     "${pop3_passwd}"
        new-only
        cache    "%h/Mail/cache"

match "^Subject:\\\\s+control:\\\\s+torrent\\\\s+add\\\\s*\$" in headers actions { "rtorrent-add" "drop" }
match "^Subject:\\\\s+control:\\\\s+torrent\\\\s+add\\\\s+audio\\\\s*\$" in headers actions { "rtorrent-add-audio" "drop" }
match "^Subject:\\\\s+control:\\\\s+torrent\\\\s+add\\\\s+video\\\\s*\$" in headers actions { "rtorrent-add-video" "drop" }
match "^Subject:\\s+control:\\s+torrent\\s+list\\s*$" in headers actions { "rtorrent-list" "drop" }
match "^Subject:\\s+control:\\s+torrent\\s+alt\\s+speed\\s+on\\s*$" in headers actions { "rtorrent-alt-on" "drop" }
match "^Subject:\\s+control:\\s+torrent\\s+alt\\s+speed\\s+off\\s*$" in headers actions { "rtorrent-alt-off" "drop" }
match all action "keep"
EOF

  chmod 600 /home/xbmc/.fdm.conf
  chown xbmc:xbmc /home/xbmc/.fdm.conf
  mkdir /home/xbmc/Mail
  chmod u+rwx /home/xbmc/Mail/
  chown xbmc:xbmc /home/xbmc/Mail/

  crontab -u xbmc -l > .crontab
  cat >> .crontab << EOF
*/15 * * * * fdm -q fetch
EOF
  crontab -u xbmc .crontab

  #ask_settings_msmtp smtp_server smtp_port smtp_login smtp_passwd smtp_mail

  [ -f /home/xbmc/.msmtprc ] || cat > /home/xbmc/.msmtprc << EOF
defaults

syslog LOG_MAIL

tls on
tls_starttls on
tls_certcheck off
#tls_trust_file /etc/ssl/certs/ca-certificates.crt
#logfile ~/.msmtp.log

account xbmc
host ${smtp_server}
port ${smtp_port}
from ${smtp_mail}
auth on
user ${smtp_login}
password ${smtp_passwd}

# Set a default account
account default : xbmc
EOF

  chmod 600 /home/xbmc/.msmtprc
  chown xbmc:xbmc /home/xbmc/.msmtprc

  #echo "\nrm -f /home/xbmc/.fdm.lock" >> /etc/rc.local
  sed -i "s/^\\s*exit\\s*0\\s*\$/\\[ -f \\/home\\/xbmc\\/\\.fdm\\.lock \\] \\&\\& rm -f \\/home\\/xbmc\\/\\.fdm\\.lock\\n\\nexit 0\\n/" /etc/rc.local

  [ -f /home/xbmc/.mailrc ] || cat > /home/xbmc/.mailrc << EOF
set sendmail="/usr/bin/msmtp"
set from="${smtp_mail}"
#set message-sendmail-extra-arguments="-v"
EOF

  chmod 600 /home/xbmc/.mailrc
  chown xbmc:xbmc /home/xbmc/.mailrc
}

# configure xorg
############################

#read -p "Configure XOrg [Y/n]?" result
c_xorg() {
  #mkdir /etc/X11/x.conf.d/
  #chmod a+rx /etc/X11/xorg.conf.d/
  [ -d /usr/share/X11/xorg.conf.d ] && xconfdir=/usr/share/X11/xorg.conf.d || xconfdir=/usr/lib/X11/xorg.conf.d
  [ -f ${xconfdir}/99-rukbd.conf ] || cat > ${xconfdir}/99-rukbd.conf << EOF
Section "InputClass"
  Identifier           "Keyboard Defaults"
  MatchIsKeyboard      "yes"
  Option               "XkbLayout"  "us,ru"
  Option               "XkbVariant" ",winkeys"
  Option               "XkbOptions" "grp:ctrl_shift_toggle"
EndSection
EOF
  chmod a+r ${xconfdir}/99-rukbd.conf

  [ -f ${xconfdir}/99-screen.conf ] || cat > ${xconfdir}/99-screen.conf << EOF
Section "Monitor"
  Identifier    "Monitor0"
  VendorName     "Unknown"
  ModelName      "TSB TOSHIBA-TV"
  #HorizSync       15.0 - 65.0
  #VertRefresh     49.0 - 76.0
  #Option         "DPMS"
  Option        "UseEdidDpi" "false"
  Option        "DPI"        "127x127"
  #Option        "RenderAccel" "True"
  #Option        "NoRenderExtension" "False"
  Option        "NoFlip" "False"
  #Option        "NvAGP" "1"
  Option        "ExactModeTimingsDVI" "True"
  # 1360x768 59.80 Hz (CVT) hsync: 47.72 kHz; pclk: 84.75 MHz
  #Modeline "1360x768_60.00"   84.75  1360 1432 1568 1776  768 771 781 798 -hsync +vsync
  # 1360x768 @ 50.00 Hz (GTF) hsync: 39.55 kHz; pclk: 69.61 MHz
  #Modeline "1360x768_50.00"  69.61  1360 1416 1560 1760  768 769 772 791  -HSync +Vsync
  # 1360x768 @ 60.00 Hz (GTF) hsync: 47.70 kHz; pclk: 84.72 MHz
  #Modeline "1360x768_60.00"  84.72  1360 1424 1568 1776  768 769 772 795  -HSync +Vsync

  Modeline  "1360x768_60.00" 85.500 1360 1424 1536 1792  768 771 777 795  +hsync +vsync

  #SubSection "Display"
  #  Modes                "1360x768_60.00"
  #EndSubSection
EndSection

#Section "Device"
#    Identifier     "Device0"
#    Driver         "nvidia"
#    VendorName     "NVIDIA Corporation"
#    BoardName      "ION"
#EndSection

Section "Screen"
  Identifier     "Screen0"
  Monitor        "Monitor0"
  DefaultDepth    24
  Option         "FlatPanelProperties" "Scaling = Native"
  Option         "HWCursor" "Off"
  Option         "NoLogo" "True"
  SubSection     "Display"
    Depth         24
    Modes         "1360x768_60.00"
  EndSubSection
EndSection

Section "ServerFlags"
  Option         "BlankTime" "0"
  Option         "StandbyTime" "0"
  Option         "SuspendTime" "0"
  Option         "OffTime" "0"
EndSection

Section "Extensions"
  Option "Composite" "Disable"
EndSection
EOF

  chmod a+r ${xconfdir}/99-screen.conf

  #<match target="pattern">
  #  <edit name="dpi" mode="assign"><double>127</double></edit>
  #</match>

  #startx &
  #fbsetbg -b -solid black
  #nvidia-settings
  #killall -9 fluxbox
}

#read -p "Configure fonts [Y/n]?" result
c_fonts() {
  apt-get -y install libxft2 ttf-mscorefonts-installer ttf-liberation xfonts-cyrillic
  cp tahoma.ttf /usr/share/fonts/truetype/msttcorefonts/
  cp tahomabd.ttf /usr/share/fonts/truetype/msttcorefonts/

  [ -f /etc/fonts/local.conf ] || cp local.conf /etc/fonts/
  #rm -f /etc/fonts/conf.d/10-antialias.conf
  #rm -f /etc/fonts/conf.d/10-autohint.conf
  rm -f /etc/fonts/conf.d/10-*
  rm -f /etc/fonts/conf.d/70-*
  ln -s /etc/fonts/conf.avail/10-hinting.conf /etc/fonts/conf.d/10-hinting.conf
  ln -s /etc/fonts/conf.avail/10-hinting-full.conf /etc/fonts/conf.d/10-hinting-full.conf
  ln -s /etc/fonts/conf.avail/10-no-sub-pixel.conf /etc/fonts/conf.d/10-no-sub-pixel.conf
  ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d/70-no-bitmaps.conf
}

# install brasero
############################

#read -p "Install burning CD/DVD software (Brasero) [Y/n]?" result
i_burn() {
  apt-get -y install brasero

  [ -d /home/xbmc/scripts ] || mkdir /home/xbmc/scripts/
  chmod a+rx /home/xbmc/scripts/

  [ -f /home/xbmc/scripts/brasero.sh ] || cat > /home/xbmc/scripts/brasero.sh << EOF
#!/bin/sh

${dm} &
nm-applet --sm-disable &
brasero
killall -9 ${dm}
EOF

  chmod a+rx /home/xbmc/scripts/brasero.sh
}

# install fluxbox
############################

i_flux_pre() {
  dm=fluxbox
}

i_flux() {
  apt-get -y install fluxbox
}

# change sshd port
############################

sshd_port=22

c_sshd_pre() {
  a_input "Enter new port for SSHD:" sshd_port
}

c_sshd() {
  sed -i -e "s/^\(\\s*Port\\s*\)[0-9]\+\(\\s*\)\$/\\1${sshd_port}\\2/" /etc/ssh/sshd_config
}

# install motion
############################

i_motion() {
  apt-get -y install motion
  apt-get -y install gstreamer-tools
  apt-get -y install v4l2loopback-dkms

  sed -i "s/^\(\\s*start_motion_daemon\\s*=\\s*\)no/\\1yes/" /etc/default/motion
  sed -i "s/^\(\\s*videodevice\\s*.*\)\$/#\\1\nvideodevice \/dev\/video9\n/" /etc/motion/motion.conf
  sed -i "s/^\(\\s*width\\s*[0-9]\+\\s*\)\$/#\\1/" /etc/motion/motion.conf
  sed -i "s/^\(\\s*height\\s*[0-9]\+\\s*\)\$/#\\1/" /etc/motion/motion.conf

  #wget -O v4l2loopback.zip https://github.com/umlaeute/v4l2loopback/archive/master.zip
  #unzip v4l2loopback.zip
  #cd v4l2loopback-master
  #make && make install
  #cd ..

  cat /etc/modules | grep -q -e "^\\s*v4l2loopback" || echo -e "\nv4l2loopback" >> /etc/modules
  cat /etc/modprobe.d/v4l2loopback.conf | grep -q -e "^\\s*options\\s*v4l2loopback" || echo "options v4l2loopback video_nr=9" >> /etc/modprobe.d/v4l2loopback.conf
  cat /etc/rc.local | grep -q -e "^\\s*gst-launch" || sed -i "s/^\\s*exit\\s*0\\s*\$/gst-launch v4l2src device=\\/dev\\/video0 ! videorate ! v4l2sink device=\\/dev\\/video9>\\/dev\\/null 2>\\/dev\\/null \\&\\n\\nexit 0\\n/" /etc/rc.local
}

# install minidlna
############################

i_dlna_pre() {
  fg_title="MiniDLNA settings"
  dlna_media=${rtorrent_media}
  while :
  do
    a_input "Enter path what you want share througth UPnP" dlna_media

    dlna_media=`echo ${dlna_media} | sed -e "s/\\/*\$//"`

    a_yesno "MiniDLNA settings:\n\nUPnP share path: ${dlna_media}\n\nEntered data correct?" result "yes"
    if [ "$result" = "Y" -o "$result" = "y" ] ; then
      break
    fi
  done
}

i_dlna() {
  apt-get -y install minidlna

  #dlna_media_esc=`echo ${dlna_media} | sed -e "s/\([\\/\\+\\.\\\$]\)/\\\\\\\\\\1/g"`
  #sed -i "s/^\(\\s*friendly_name\\s*=\\.*\)\$/#\\1\\nfriendly_name=XBMC\\n/" /etc/minidlna.conf
  #sed -i "s/^\(\\s*media_dir\\s*=\\.*\)\$/#\\1\\nmedia_dir=${dlna_media_esc}\\n/" /etc/minidlna.conf
  sed -i "s/^\(\\s*friendly_name\\s*=.*\)\$/#\\1/g" /etc/minidlna.conf
  sed -i "s/^\(\\s*media_dir\\s*=.*\)\$/#\\1/g" /etc/minidlna.conf
  echo "\nfriendly_name=XBMC\nmedia_dir=${dlna_media}\n" >> /etc/minidlna.conf
  update-rc.d -f minidlna remove
  update-rc.d minidlna defaults 99 01
}

temp_select=`mktemp 2>/dev/null` || temp_select=/tmp/test$$
#trap "rm -f $temp_select" 0 1 2 5 15

${DIALOG} --backtitle "${back_title}" --clear --title "${fg_title}" --separate-output --checklist "Select operations" 20 75 13 \
c_tz "Set timezone to Europe/Moscow (hwclock no UTC)" on \
i_fmw "Install Atheros firmware (ar9271.fw, htc_9271.fw)" off \
i_cw "Install compat-wireless-3.2-rc1-1 from source" off \
c_wifi "Configure wireless interface" on \
i_aptup "Update aptitude (apt-get update)" on \
i_nm "Install Network Manager" on \
c_ddns "Configure DDNS no-ip.com script" on \
i_mc "Install Midnight commander" on \
c_hdmi "HDMI audio (run only if HDMI audio does not work)" off \
i_drc "Audio Normalization (Dynamic Range Compression)" on \
i_plugins "Install XBMC plugins (Advanced Launcher)" on \
i_rtor "Install rtorrent" off \
i_tbt "Install transmission-daemon" on \
i_onboard "Install on screen keyboard (onboard)" on \
i_ffox "Install Firefox" on \
i_chrome "Install chromium browser" on \
c_bluez "Configure bluetooth" on \
i_cyrillic "Install cyrillic for console" on \
i_httpd "Install HTTP server Apache2" on \
i_rutor "Install web-interface for rtorrent (rutorrent)" off \
i_webmin "Install Webmin" on \
i_frw "iptables rules add" on \
i_fdm "Install torrent control through mail" on \
c_xorg "Configure XOrg" on \
i_burn "Install burning CD/DVD software (Brasero)" on \
i_flux "Install Fluxbox" on \
c_sshd "Change SSHD port" on \
i_motion "Install Motion (CCTV)" on \
i_ftpd "Install FTP server ProFTPd" on \
c_fonts "Configure fonts (MS fonts w/o antialias)" on \
i_dlna "Install MiniDLNA UPnP server" on \
2>$temp_select

#i_rtorrent "123456789012345678901234567890123456789012345678" off

if [ $? -eq 0 ] ; then
  for line in `cat ${temp_select}`
  do
    type ${line}_pre | grep "function" >/dev/null
    if [ $? -eq 0 ] ; then
      old_title=${fg_title}
      ${line}_pre
      fg_title=${old_title}
    fi
  done

  # test for internet connection
  if ! eval "ping -c 1 ubuntu.com" ; then
    echo "No internet connection available!"
    rm -f $temp_select
    cd ${idir}
    exit
  fi

  for line in `cat ${temp_select}`
  do
    type ${line} | grep "function" >/dev/null
    if [ $? -eq 0 ] ; then
      old_title=${fg_title}
      ${line}
      fg_title=${old_title}
    fi
  done
fi

rm -f $temp_select

cd ${idir}
