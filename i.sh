#!/bin/sh

# Install Arch Linux as described in official wiki
# Optional: Create partition for torrents and mount to /mnt/data
# Run this script for install and configure Kodi

# Boot XBMCbuntu, CTRL+ALT+F1, login and run:
# wget https://raw.githubusercontent.com/pfzim/xbmc-config/master/i.sh
# chmod a+rx i.sh
# sudo ./i.sh

# --wget http://hencvik.googlecode.com/files/i.sh
# --./i.sh 2>&1 | tee i.log

back_title="XBMC 18.5 post installation configuration script v0.09.01 (c) pfzim"
fg_title="XBMC configuration"
DIALOG=whiptail
idir=$(pwd)
dm=fluxbox
username=xbmc

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


# ask user name for run xbmc
c_user_pre() {
	a_input "Enter username for run XBMC (must be exist):" username

	# useradd -m -G wheel,sudo xbmc
	# useradd -m xbmc
	# passwd xbmc
}

# set timezone
############################

c_tz() {
	timedatectl set-ntp true
	rm -f /etc/localtime
	ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
	hwclock --systohc
}

# update arch
############################

i_update() {
	pacman -Syu --noconfirm
}

# Configure wireless interface
##############################

ask_settings_ip() {
	while :
	do
		a_input "Enter IP address [$1]:" $1
		a_input "Enter network prefix [$2]:" $2
		a_input "Enter gateway [$3]:" $3
		a_input "Enter DNS1 [$4]:" $4
		a_input "Enter DNS2 [$5]:" $5
		a_input "Enter Metric [$6]:" $6

		eval "a_yesno \"Network settings:\\n\\nIP: \$$1\nMask: \$$2\\nGateway: \$$3\\nDNS1: \$$4\\nDNS2: \$$5\\nMetric: \$$5\\n\\nEntered data correct?\" result"
		if [ "$result" = "Y" -o "$result" = "y" ] ; then
			break
		fi
	done
}

ask_settings_pass() {
	while :
	do
		a_passwd "Enter password for wireless network:" p1

		if [ "${#p1}" -ge 8 -a "${#p1}" -le 63 ] ; then
			eval "$1=$p1"
			break
		else
			a_msgbox "Passphrase must be 8..63 characters"
		fi
	done
}

c_net_pre() {
	pacman -S --noconfirm --needed wpa_supplicant

	systemctl start systemd-networkd

	fg_title="Network configuration"

	while :
	do
		# list_items=<interface>;net_type=<type>
		list_items=$(networkctl --no-legend list | awk '{ print $2 ";net_type=" $3 }')

		# list_menu=<interface> <type>
		list_menu=$(echo "${list_items}" | sed -e "s/^\([^;]\+\);net_type=\(.*\)\$/\1 \2/")
		#list_menu="${list_menu}\nrescan \"Find new networks...\""
		#list_menu="${list_menu}\nback \"Back to previous menu\""

		#echo $list_menu
		#exit 0

		if [ -z "${list_menu}" ] ; then
			a_msgbox "ERROR: Something gone wrong..."
			break
		fi

		tempfile=`mktemp 2>/dev/null` || tempfile=/tmp/test$$
		#trap "rm -f $tempfile" 0 1 2 5 15

		eval ${DIALOG} --backtitle \"${back_title}\" --clear --title \"Network configuration\" --menu \"Select network inteface\" 20 75 13 ${list_menu} 2>$tempfile

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

		eval $(echo "${list_items}" | grep "^${net_if};" | sed -e "s/^[^;]\+;//")

		if [ "${net_type}" = "loopback" ] ; then
			continue
		fi

		net_metric="20"

		if [ "${net_type}" = "wlan" ] ; then
			net_metric="50"

			#ifconfig ${net_if} up

			[ -f /etc/wpa_supplicant/wpa_supplicant.conf ] || cat > /etc/wpa_supplicant/wpa_supplicant.conf <<- EOF
				ctrl_interface=/run/wpa_supplicant
				#update_config=1
			EOF

			wpa_supplicant -B -i${net_if} -c/etc/wpa_supplicant/wpa_supplicant.conf
			wpa_cli -i${net_if} scan
			echo "Wait for 5 seconds. Scanning WiFi..."
			sleep 5

			# list_items = <SSID>;ap_type=<WPA|WEP|OPEN>
			list_items=$(wpa_cli -i${net_if} scan_results | awk '{
				if(NR > 2)
				{
					if(match($4, /WEP|WPA/, m))
					{
						print $5 ";ap_etype=" m[0];
					}
					else
					{
						print $5 ";ap_etype=OPEN";
					}
				}
			}')

			list_menu=$(echo "${list_items}" | sed -e "s/^\([^;]\+\);ap_etype=\(.*\)\$/\1 \2/")
			#list_menu="${list_menu}\nrescan \"Find new networks...\""
			#list_menu="${list_menu}\nback \"Back to previous menu\""

			#echo $list_menu
			#exit 0

			#echo "*** RESULT ***"
			#echo "${list_items}"
			#echo "*** RESULT ***"
			#echo "*** RESULT ***"
			#echo "${list_menu}"
			#echo "*** RESULT ***"

			if [ -z "${list_items}" ] ; then
				a_msgbox "No one WiFi networks found. Try scan again"
				continue
			fi

			eval ${DIALOG} --backtitle \"${back_title}\" --clear --title \"Wireless network configuration\" --menu \"Select WiFi accesspoint\" 20 75 13 ${list_menu} 2>$tempfile

			if [ $? -ne 0 ] ; then
				rm -f $tempfile
				continue
			fi

			sel_item=$(cat $tempfile)
			rm -f $tempfile

			if [ "${sel_item}" = "back" ] ; then
				continue
			fi

			eval $(echo "${list_items}" | grep "^${sel_item};" | sed -e "s/^[^;]\+;//")

			ap_essid=$sel_item

			#echo "AP_INFO: ${ap_info}"
			#echo "MAC: ${ap_mac}"
			#echo "ESSID: ${ap_essid}"
			#echo "ENC-TYPE: ${ap_etype}"

			if [ "${ap_etype}" = "WPA" ]  ; then
				ask_settings_pass ap_pass
				wpa_cfg=$(wpa_passphrase "${ap_essid}" "${ap_pass}")
			elif [ "${ap_etype}" = "WEP" ]  ; then
				ask_settings_pass ap_pass
				wpa_cfg=$(cat <<- END
					ssid="${ap_essid}"
					key_mgmt=NONE
					wep_key0="${ap_pass}"
					wep_tx_keyidx=0
				END
				)
			else
				wpa_cfg=$(cat <<- END
					ssid="${ap_essid}"
					key_mgmt=NONE
				END
				)
			fi
		fi

		a_yesno "Use DHCP?" result "yes"
		if [ "$result" = "Y" -o "$result" = "y" ] ; then

			a_input "Enter Metric [${net_metric}]:" net_metric

			net_cfg=$(cat <<- END
				[Match]
				Name=${net_if}

				[Network]
				DHCP=yes

				[DHCPV4]
				RouteMetric=${net_metric}
			END
			)
		else
			net_ip="192.168.1.100"
			net_prefix="24"
			net_gw="192.168.1.1"
			net_dns1="192.168.1.1"
			net_dns2=""

			ask_settings_ip net_ip net_prefix net_gw net_dns1 net_dns2 net_metric

			net_dns=""
			if [ -n "${net_dns1}" -o -n "${net_dns2}" ] ; then
				if [ -n "${net_dns1}" ] ; then
					net_dns="DNS=${net_dns1}\n"
				fi
				if [ -n "${net_dns2}" ] ; then
					net_dns="${net_dns}DNS=${net_dns2}\n"
				fi
			fi

			net_cfg=$(cat <<- END
				[Match]
				Name=${net_if}

				[Network]
				${net_dns}

				[Address]
				Address=${net_ip}/${net_prefix}

				[Route]
				Gateway=${net_gw}
				Destination=${net_mask}
				Metric=${net_metric}
			END
			)
		fi

		if [ "${net_type}" = "wlan" ] ; then
			a_yesno "/etc/wpa_supplicant/wpa_supplicant-${net_if}.conf:\n${wpa_cfg}\n\nSave this configuration?" result "yes"
			if [ "$result" = "Y" -o "$result" = "y" ] ; then
				echo -ne "$wpa_cfg" > "/etc/wpa_supplicant/wpa_supplicant-${net_if}.conf"

				systemctl enable "wpa_supplicant@${net_if}"
			fi
		fi

		a_yesno "/etc/systemd/network/90-network-${net_if}.network:\n${net_cfg}\n\nSave this configuration?" result "yes"
		if [ "$result" = "Y" -o "$result" = "y" ] ; then
			echo -ne "$net_cfg" > "/etc/systemd/network/90-network-${net_if}.network"

			systemctl enable systemd-networkd
			systemctl enable systemd-resolved
		fi

		a_yesno "${net_res}\nConnect NOW using this configuration?" result "yes"
		if [ "$result" = "Y" -o "$result" = "y" ] ; then
			if [ "${net_type}" = "wlan" ]  ; then
				systemctl restart "wpa_supplicant@${net_if}"
			fi

			systemctl restart systemd-networkd
			systemctl restart systemd-resolved
		fi
	done
}

# install NetworkManager
############################

#read -p "Install Network Manager [Y/n]?" result
i_nm() {
	pacman -S --noconfirm --needed networkmanager
	#sed -i "s/\(\\s*managed\\s*=\\s*\)false/\\1true/" /etc/NetworkManager/NetworkManager.conf
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
	pacman -S --noconfirm --needed cronie curl

	crontab -u $username -l > .crontab
	cat >> .crontab <<- EOF
		# curl version
		*/15 * * * * curl --silent --basic --user "${noip_user}:${noip_passwd}" --user-agent "curl based script/0.01 pfzim@mail.ru" "http://dynupdate.no-ip.com/nic/update?hostname=${noip_host}" --output /dev/null

		# wget version
		# */15 * * * * wget --quiet --delete-after --auth-no-challenge --user="${noip_user}" --password="${noip_passwd}" --user-agent="wget based script/0.01 pfzim@mail.ru" "http://dynupdate.no-ip.com/nic/update?hostname=${noip_host}"
	EOF
	crontab -u $username .crontab
}

# install console tools
############################

i_mc() {
	pacman -S --noconfirm --needed mc man bash-completion sudo cronie
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

# install transmission-daemon
##############################

torrent_media="/mnt/data/torrents"
torrent_sess="/mnt/data/transmission"

i_tbt_pre() {
	fg_title="transmission-daemon settings"
	while :
	do
		a_input "Enter path where you want save torrent download" torrent_media
		a_input "Enter path where you want save torrent session data" torrent_sess

		torrent_media=`echo ${torrent_media} | sed -e "s/\\/*\$//"`
		torrent_sess=`echo ${torrent_sess} | sed -e "s/\\/*\$//"`

		a_yesno "transmission-daemon settings:\n\nDownloads path: ${torrent_media}\nSession path: ${torrent_sess}\n\nEntered data correct?" result "yes"
		if [ "$result" = "Y" -o "$result" = "y" ] ; then
			break
		fi
	done
}

i_tbt() {
	pacman -S --noconfirm --needed transmission-cli

	systemctl start transmission

	config="/var/lib/transmission/.config/transmission-daemon/settings.json"

	if [ ! -d "${torrent_sess}" ] ; then
		mkdir -p "${torrent_sess}"
	fi

	if [ ! -d "${torrent_sess}/_control" ] ; then
		mkdir -p "${torrent_sess}/_control"
		chmod a+rwx "${torrent_sess}/_control"
	fi

	if [ ! -d "${torrent_sess}/resume" ] ; then
		mkdir -p "${torrent_sess}/resume"
		chmod 755 "${torrent_sess}/resume"
		chown -R transmission:transmission "${torrent_sess}/resume"
	fi

	if [ ! -d "${torrent_sess}/torrents" ] ; then
		mkdir -p "${torrent_sess}/torrents"
		chmod 755 "${torrent_sess}/torrents"
		chown -R transmission:transmission "${torrent_sess}/torrents"
	fi

	if [ ! -d "${torrent_media}" ] ; then
		mkdir -p "${torrent_media}"
		chmod a+rwx "${torrent_media}"
	fi

	mv -fT /var/lib/transmission/.config/transmission-daemon/resume "${torrent_sess}/resume"
	mv -fT /var/lib/transmission/.config/transmission-daemon/torrents "${torrent_sess}/torrents"

	rm -rf /var/lib/transmission/.config/transmission-daemon/resume
	rm -rf /var/lib/transmission/.config/transmission-daemon/torrents

	ln -sf "${torrent_sess}/resume/" /var/lib/transmission/.config/transmission-daemon/resume
	ln -sf "${torrent_sess}/torrents/" /var/lib/transmission/.config/transmission-daemon/torrents

	torrent_media_esc=`echo ${torrent_media} | sed -e "s/\([\\/\\+\\.\\\$]\)/\\\\\\\\\\1/g"`
	torrent_sess_esc=`echo ${torrent_sess} | sed -e "s/\([\\/\\+\\.\\\$]\)/\\\\\\\\\\1/g"`

	sed -i "s/^\(\\s*{\)/\\1\\n    \"watch-dir\": \"${torrent_sess_esc}\\/_control\\/\",\\n    \"watch-dir-enabled\": true,/" $config
	sed -i "s/\"download-dir\": [^,]*/\"download-dir\": \"${torrent_media_esc}\\/\"/" $config
	sed -i "s/\"rpc-authentication-required\": [^,]*/\"rpc-authentication-required\": false/" $config

	systemctl enable transmission
	systemctl restart transmission
}

# install onboard
############################

#read -p "Install on screen keyboard (onboard) [Y/n]?" result
i_onboard() {
	pacman -S --noconfirm --needed onboard
}

# install firefox
############################

#read -p "Install firefox [Y/n]?" result
i_ffox() {
	pacman -S --noconfirm --needed firefox

	if [ ! -d "/home/${username}/scripts" ] ; then
		mkdir "/home/${username}/scripts"
		chmod a+rx "/home/${username}/scripts"
	fi

	if [ ! -f "/home/${username}/scripts/firefox.sh" ] ; then
		cat > "/home/${username}/scripts/firefox.sh" <<- EOF
			#!/bin/sh

			#${dm} &
			#nm-applet --sm-disable &
			firefox
			#killall -9 ${dm}
		EOF

		chmod a+rx "/home/${username}/scripts/firefox.sh"
	fi
}

# install chromium
############################

i_chrome() {
	pacman -S --noconfirm --needed chromium

	if [ ! -d "/home/${username}/scripts" ] ; then
		mkdir "/home/${username}/scripts"
		chmod a+rx "/home/${username}/scripts"
	fi

	if [ ! -f "/home/${username}/scripts/chrome.sh" ] ; then
		cat > "/home/${username}/scripts/chrome.sh" <<- EOF
			#!/bin/sh

			#${dm} &
			#nm-applet --sm-disable &
			chromium-browser
			#killall -9 ${dm}
		EOF

		chmod a+rx "/home/${username}/scripts/chrome.sh"
	fi
}

# configure bluetooth
############################

c_bluez() {
	pacman -S --noconfirm --needed bluez bluez-utils
	#modprobe hidp
	#cat /etc/modules | grep -q -e "^\\s*hidp\\s*\$" || echo "hidp" >> /etc/modules
	#/etc/init.d/bluetooth restart

	#hci_device="hci0"

	systemctl enable bluetooth
	systemctl start bluetooth

	config="/etc/bluetooth/main.conf"

	sed -i -e "/^\\s*AutoEnable\\s*=/ s/^/#/" $config
	sed -i -e "/^\\s*\\[Policy\\]/a AutoEnable=true" $config


	while :
	do

		list_items=$(bluetoothctl list | grep -e "^Controller\\s*\([A-F0-9]\{2\}:\)\{5\}[A-F0-9]\{2\}\\s" | sed -e "s/^Controller\\s*\(\([A-F0-9]\{2\}:\)\{5\}[A-F0-9]\{2\}\)\\s.*\$/\\1/" |
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

			bluetoothctl -- select ${hci_device}
			bluetoothctl power on

			#${DIALOG} --backtitle "${back_title}" --clear --title "XBMC configuration" --msgbox "Initialise pairing mode on connected device and press Enter..." 10 75
			a_msgbox "Initialise pairing mode on connected device and press Enter..."
			#read -p "Initialise pairing mode on connected device and press Enter..." result
			echo -ne "\n\nSomtimes bluetooth daemon crash. Then you need switch to other console Alt+F2 and run daemon again 'systemctl start bluetooth' for continue setup.\n\nScanning for bluetooth devices...\n"

			{ echo -e "scan on"
				sleep 5
				echo -e "\nscan off"
				echo -e "quit"
			} | bluetoothctl
			# > /dev/null

			bluetoothctl agent on
			bluetoothctl default-agent

			list_items=$(bluetoothctl devices | sed -e "s/^Device\\s\+//" |
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
						bluetoothctl -- pair ${dev_addr}
						bluetoothctl -- trust ${dev_addr}
						bluetoothctl -- connect ${dev_addr}
					fi
				fi

				rm -f $tempfile
			fi
		fi
	done
}

# configure console
############################

i_cyrillic() {
	config="/etc/vconsole.conf"

	sed -i -e "/^\\s*KEYMAP\\s*=/ s/^/#/" $config
	sed -i -e "/^\\s*FONT\\s*=/ s/^/#/" $config
	echo -ne "\nKEYMAP=ru\nFONT=pancyrillic.f16\n" >> $config
}


# install apache and php
############################

i_httpd() {
	pacman -S --noconfirm --needed apache php php-apache
}

# install proftpd
############################

# install rutorrent
############################

# install webmin
############################

# install iptables
############################

i_frw() {
	systemctl enable iptables
	systemctl start iptables

	iptables -A PREROUTING -t mangle -p tcp --sport 0:1024 -j TOS --set-tos Minimize-Delay
	iptables -A PREROUTING -t mangle -p tcp --sport 1025:65535 -j TOS --set-tos Maximize-Throughput
	iptables -A OUTPUT -t mangle -p tcp --dport 0:1024 -j TOS --set-tos Minimize-Delay
	iptables -A OUTPUT -t mangle -p tcp --dport 1025:65535 -j TOS --set-tos Maximize-Throughput

	iptables-save > /etc/iptables/iptables.rules

	#if ! eval "cat /etc/network/interfaces | grep -v -e \"^\\\\s*#\" | grep -q -e \"/etc/iptables.up.rules\"" ; then
	#  sed -i "/iface\\s*lo/a\\\\tpost-up iptables-restore < /etc/iptables.up.rules" /etc/network/interfaces
	#fi
}

# install torrent control through mail
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

torrent_dir="${torrent_sess}/_control"

ask_settings_fdm_torrent_dir() {
	while :
	do
		a_input "Enter directory for save torrents: " $1

		eval "a_yesno \"Directory watched by transmission daemon:\\n\$$1\\n\\nEntered data correct?\" result \"yes\""
		if [ "$result" = "Y" -o "$result" = "y" ] ; then
			break
		fi
	done
}

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

i_fdm_pre() {
	fg_title="FDM settings for remote control through mail (POP3/SMTP)"
	ask_settings_fdm_torrent_dir torrent_dir
	ask_settings_fdm pop3_server pop3_port pop3_login pop3_passwd
	ask_settings_msmtp smtp_server smtp_port smtp_login smtp_passwd smtp_mail

	torrent_dir=`echo ${torrent_dir} | sed -e "s/\\/*\$//"`
}

i_fdm() {
	pacman -S --noconfirm --needed fdm msmtp s-nail
	pacman -U --noconfirm --needed mpack-1.6-4-x86_64.pkg.tar.xz

	if [ ! -f "/home/${username}/scripts/control-reply.sh" ] ; then
		cat > "/home/${username}/scripts/control-reply.sh" << EOF
#!/bin/sh

if [ "\$#" -ne 1 ] ; then
	exit 1
fi

from=\`sed -e "/^.\\\$/q" | grep "^From:" | sed -n -e "s/^From: [^<]*<\(.*\)>\\\$/\1/p;s/^From: \([^<>]\+\)\\\$/\1/p" | head -n 1\`
cc=

if [ -n "\${from}" ] ; then
	echo \${from} | grep -qi "^${smtp_mail}"
	if [ $? -ne 0 ] ; then
		cc="-b \"${smtp_mail}\""
	fi
else
	from="${smtp_mail}"
fi

eval "(\$1) | mailx -s \"Operation result\"\${cc} \"\${from}\""
EOF

		chmod 600 "/home/${username}/scripts/control-reply.sh"
		chown "${username}:${username}" "/home/${username}/scripts/control-reply.sh"
	fi

	if [ ! -f "/home/${username}/.fdm.conf" ] ; then
		cat > "/home/${username}/.fdm.conf" << EOF
set maximum-size      10M
set delete-oversized
set queue-high        1
set queue-low         0
set purge-after       10
set unmatched-mail    keep

action "drop" drop
action "keep" keep

action "inbox" maildir "%h/Mail/INBOX"
action "torrent-add" pipe "munpack -f -q -C ${torrent_dir}/ ; for i in ${torrent_dir}/*.torrent ; do chmod a+r \\\$i ; done"
action "torrent-add-audio" pipe "munpack -f -q -C ${torrent_dir}/audio/ ; for i in ${torrent_dir}/audio/*.torrent ; do chmod a+r \\\$i ; done"
action "torrent-add-video" pipe "munpack -f -q -C ${torrent_dir}/video/ ; for i in ${torrent_dir}/video/*.torrent ; do chmod a+r \\\$i ; done"
action "torrent-list" pipe "/home/${username}/scripts/control-reply.sh \"df -h ; transmission-remote -si -st -l\""
action "torrent-alt-on" exec "transmission-remote --alt-speed"
action "torrent-alt-off" exec "transmission-remote --no-alt-speed"

account "xbmc"
				pop3s
				server   "${pop3_server}"
				port     ${pop3_port}
				user     "${pop3_login}"
				pass     "${pop3_passwd}"
				new-only
				cache    "%h/Mail/cache"

match "^Subject:\\\\s+control:\\\\s+torrent\\\\s+add\\\\s*\$" in headers actions { "torrent-add" "drop" }
match "^Subject:\\\\s+control:\\\\s+torrent\\\\s+add\\\\s+audio\\\\s*\$" in headers actions { "torrent-add-audio" "drop" }
match "^Subject:\\\\s+control:\\\\s+torrent\\\\s+add\\\\s+video\\\\s*\$" in headers actions { "torrent-add-video" "drop" }
match "^Subject:\\\\s+control:\\\\s+torrent\\\\s+list\\\\s*\$" in headers actions { "torrent-list" "drop" }
match "^Subject:\\\\s+control:\\\\s+torrent\\\\s+alt\\\\s+speed\\\\s+on\\\\s*\$" in headers actions { "torrent-alt-on" "drop" }
match "^Subject:\\\\s+control:\\\\s+torrent\\\\s+alt\\\\s+speed\\\\s+off\\\\s*\$" in headers actions { "torrent-alt-off" "drop" }
match all action "keep"
EOF

		chmod 600 "/home/${username}/.fdm.conf"
		chown "${username}:${username}" "/home/${username}/.fdm.conf"
	fi

	if [ ! -d "/home/${username}/Mail" ] ; then
		mkdir "/home/${username}/Mail"
		chmod u+rwx "/home/${username}/Mail"
		chown "${username}:${username}" "/home/${username}/Mail"
	fi

	if ! crontab -u $username -l | grep -qFe "fdm -q fetch" ; then
		crontab -u $username -l > .crontab
		cat >> .crontab <<- EOF
			*/15 * * * * rm -f "/home/${username}/.fdm.lock"; fdm -q fetch
		EOF
		crontab -u $username .crontab
	fi

	if [ ! -f "/home/${username}/.msmtprc" ] ; then
		cat > "/home/${username}/.msmtprc" <<- EOF
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

		chmod 600 "/home/${username}/.msmtprc"
		chown "${username}:${username}" "/home/${username}/.msmtprc"
	fi

	#echo "\nrm -f /home/${username}/.fdm.lock" >> /etc/rc.local
	#sed -i "s/^\\s*exit\\s*0\\s*\$/\\[ -f \\/home\\/${username}\\/\\.fdm\\.lock \\] \\&\\& rm -f \\/home\\/${username}\\/\\.fdm\\.lock\\n\\nexit 0\\n/" /etc/rc.local

	if [ ! -f "/home/${username}/.mailrc" ] ; then
		cat > "/home/${username}/.mailrc" <<- EOF
			set sendmail="/usr/bin/msmtp"
			set from="${smtp_mail}"
			#set message-sendmail-extra-arguments="-v"
		EOF

		chmod 600 "/home/${username}/.mailrc"
		chown "${username}:${username}" "/home/${username}/.mailrc"
	fi
}

# configure xorg
############################

#read -p "Configure XOrg [Y/n]?" result
c_xorg() {
	[ -d /etc/X11/xorg.conf.d ] && xconfdir=/etc/X11/xorg.conf.d || xconfdir=/usr/share/X11/xorg.conf.d

	if [ ! -f ${xconfdir}/99-rukbd.conf ] ; then
		cat > ${xconfdir}/99-rukbd.conf << EOF
Section "InputClass"
	Identifier           "Keyboard Defaults"
	MatchIsKeyboard      "yes"
	Option               "XkbLayout"  "us,ru"
	Option               "XkbVariant" ",winkeys"
	Option               "XkbOptions" "grp:ctrl_shift_toggle"
EndSection
EOF
		chmod a+r ${xconfdir}/99-rukbd.conf
	fi

	if [ ! -f ${xconfdir}/99-screen.conf ] ; then
		cat > ${xconfdir}/99-screen.conf << EOF
Section "Monitor"
	Identifier    "Monitor0"
	VendorName     "Unknown"
	ModelName      "TSB TOSHIBA-TV"

	#HorizSync       15.0 - 65.0
	#VertRefresh     49.0 - 76.0
	#Option         "DPMS"
	#Option        "RenderAccel" "True"
	#Option        "NoRenderExtension" "False"
	#Option        "NvAGP" "1"

	Option        "UseEdidDpi" "false"
	Option        "DPI"        "127x127"
	Option        "NoFlip" "False"
	Option        "ExactModeTimingsDVI" "True"

	Modeline  "1360x768_60.00" 85.500 1360 1424 1536 1792  768 771 777 795  +hsync +vsync


	# 1360x768 59.80 Hz (CVT) hsync: 47.72 kHz; pclk: 84.75 MHz
	#Modeline "1360x768_60.00"   84.75  1360 1432 1568 1776  768 771 781 798 -hsync +vsync
	# 1360x768 @ 50.00 Hz (GTF) hsync: 39.55 kHz; pclk: 69.61 MHz
	#Modeline "1360x768_50.00"  69.61  1360 1416 1560 1760  768 769 772 791  -HSync +Vsync
	# 1360x768 @ 60.00 Hz (GTF) hsync: 47.70 kHz; pclk: 84.72 MHz
	#Modeline "1360x768_60.00"  84.72  1360 1424 1568 1776  768 769 772 795  -HSync +Vsync

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
	fi

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
	[ -f /etc/fonts/local.conf ] || cp local.conf /etc/fonts/
	mv -fT microsoft /usr/share/fonts/microsoft
	fc-cache -f

	#rm -f /etc/fonts/conf.d/10-*
	#rm -f /etc/fonts/conf.d/70-*
	#ln -s /etc/fonts/conf.avail/10-hinting.conf /etc/fonts/conf.d/10-hinting.conf
	#ln -s /etc/fonts/conf.avail/10-hinting-full.conf /etc/fonts/conf.d/10-hinting-full.conf
	#ln -s /etc/fonts/conf.avail/10-no-sub-pixel.conf /etc/fonts/conf.d/10-no-sub-pixel.conf
	#ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d/70-no-bitmaps.conf
}

# install brasero
############################

#read -p "Install burning CD/DVD software (Brasero) [Y/n]?" result
i_burn() {
	pacman -S --noconfirm --needed brasero

	if [ ! -d "/home/${username}/scripts" ] ; then
		mkdir "/home/${username}/scripts"
		chmod a+rx "/home/${username}/scripts"
	fi

	if [ ! -f "/home/${username}/scripts/brasero.sh" ] ; then
		cat > "/home/${username}/scripts/brasero.sh" <<- EOF
			#!/bin/sh

			#${dm} &
			#nm-applet --sm-disable &
			brasero
			#killall -9 ${dm}
		EOF

		chmod a+rx "/home/${username}/scripts/brasero.sh"
	fi
}

# install kodi
############################
i_kodi() {
	pacman -S --noconfirm --needed xorg fluxbox lxdm kodi

	config="/etc/lxdm/lxdm.conf"

	sed -i -e "/^\\s*autologin\\s*=/ s/^/#/" $config
	sed -i -e "/^\\s*\\[base\\]/a autologin=${username}" $config

	config="/home/${username}/.fluxbox/startup"

	if [ ! -f $config ] ; then
		[ -d /home/${username}/.fluxbox ] || mkdir -p /home/${username}/.fluxbox
		cat > $config <<- EOF
			#!/bin/sh
			#
			# fluxbox startup-script:
			#
			# Lines starting with a '#' are ignored.

			# Change your keymap:
			xmodmap "$HOME/.Xmodmap"

			# Applications you want to run with fluxbox.
			# MAKE SURE THAT APPS THAT KEEP RUNNING HAVE AN ''&'' AT THE END.
			#
			# unclutter -idle 2 &
			# wmnd &
			# wmsmixer -w &
			# idesk &

			kodi &

			# And last but not least we start fluxbox.
			# Because it is the last app you have to run it with ''exec'' before it.

			exec fluxbox
			# or if you want to keep a log:
			# exec fluxbox -log "$fluxdir/log"
		EOF

		chmod 644 $config
	else
		sed -i -e "/^\\s*exec\\s\+fluxbox/ s/^/kodi &\n\n/" $config
	fi


	config="/home/${username}/.dmrc"

	if [ ! -f $config ] ; then
		cat > $config <<- EOF
			[Desktop]
			Session=fluxbox
		EOF

		chmod 644 $config
		chown ${username}:${username} $config
	fi

	systemctl enable lxdm
}

# change sshd port
############################

sshd_port=22

i_sshd_pre() {
	a_input "Enter new port for SSHD:" sshd_port
}

i_sshd() {
	pacman -S --noconfirm --needed openssh

	config="/etc/ssh/sshd_config"

	sed -i -e "/^\\s*Port\\s*/ s/^/#/" $config
	echo -ne "\nPort ${sshd_port}\n" >> $config

	systemctl enable sshd
	systemctl start sshd
}

# install motion
############################

i_motion() {
	pacman -S --noconfirm --needed motion gstreamer gst-plugins-good linux-headers
	pacman -U --noconfirm --needed v4l2loopback-dkms-0.12.3-1-x86_64.pkg.tar.xz

	config="/etc/motion/motion.conf"

	if [ ! -d "/var/motion" ] ; then
		mkdir -p /var/motion
		chown motion:motion /var/motion
		chmod a+rwx /var/motion
	fi

	[ -f "/etc/modprobe.d/v4l2loopback.conf" ] || cat > /etc/modprobe.d/v4l2loopback.conf <<- EOF
		options v4l2loopback video_nr=9
	EOF

	[ -f "/etc/modules-load.d/v4l2loopback.conf" ] || cat > /etc/modules-load.d/v4l2loopback.conf <<- EOF
		v4l2loopback
	EOF

	[ -f "/etc/systemd/system/gst-video9.service" ] || cat > /etc/systemd/system/gst-video9.service <<- EOF
		[Unit]
		Description=GST Loopback video9
		After=local-fs.target
		Before=motion.service

		[Service]
		User=motion
		ExecStart=/usr/bin/gst-launch-1.0 v4l2src device=/dev/video0 ! videorate ! v4l2sink device=/dev/video9
		Type=simple
		StandardError=null

		[Install]
		WantedBy=multi-user.target
	EOF

	#sed -i "s/^\(\\s*start_motion_daemon\\s*=\\s*\)no/\\1yes/" $config

	sed -i "/^\\s*videodevice\\s*/ s/^/#/" $config
	sed -i "/^\\s*width\\s*/ s/^/#/" $config
	sed -i "/^\\s*height\\s*/ s/^/#/" $config
	sed -i "/^\\s*target_dir\\s*/ s/^/#/" $config
	sed -i "/^\\s*movie_filename\\s*/ s/^/#/" $config

	echo -ne "\ntarget_dir /var/motion\n" >> $config
	echo -ne "movie_filename backup-%Y-%m-%d-%H%M%S-%t-%v\n" >> $config
	echo -ne "videodevice /dev/video9\n" >> $config

	cp rotate9-motion.sh /usr/sbin/

	crontab -u motion -l > .crontab
	cat >> .crontab <<- EOF
		18 2 * * * /usr/sbin/rotate9-motion.sh
		@reboot /usr/sbin/rotate9-motion.sh
	EOF
	crontab -u motion .crontab

	#wget -O v4l2loopback.zip https://github.com/umlaeute/v4l2loopback/archive/master.zip
	#unzip v4l2loopback.zip
	#cd v4l2loopback-master
	#make && make install
	#cd ..

	#cat /etc/modules | grep -q -e "^\\s*v4l2loopback" || echo -e "\nv4l2loopback" >> /etc/modules
	#cat /etc/modprobe.d/v4l2loopback.conf | grep -q -e "^\\s*options\\s*v4l2loopback" || echo "options v4l2loopback video_nr=9" >> /etc/modprobe.d/v4l2loopback.conf
	#cat /etc/rc.local | grep -q -e "^\\s*gst-launch" || sed -i "s/^\\s*exit\\s*0\\s*\$/gst-launch v4l2src device=\\/dev\\/video0 ! videorate ! v4l2sink device=\\/dev\\/video9>\\/dev\\/null 2>\\/dev\\/null \\&\\n\\nexit 0\\n/" /etc/rc.local

	systemctl enable gst-video9.service
	systemctl start gst-video9.service

	systemctl enable motion
	systemctl start motion
}

# install minidlna
############################

i_dlna_pre() {
	fg_title="MiniDLNA settings"
	dlna_media=${torrent_media}
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
	config="/etc/minidlna.conf"
	pacman -S --noconfirm --needed minidlna

	sed -i "/^\\s*friendly_name\\s*=/ s/^/#/" $config
	sed -i "/^\\s*media_dir\\s*=/ s/^/#/" $config
	echo -ne "\nfriendly_name=XBMC\nmedia_dir=${dlna_media}\n" >> $config

	#update-rc.d -f minidlna remove
	#update-rc.d minidlna defaults 99 01
	systemctl enable minidlna
	systemctl start minidlna
}


if [ "$(id -u)" != "0" ]; then
	echo "Sorry, you must execute me with sudo."
	exit 1
fi

c_user_pre

[ -d xbmc_install ] || mkdir xbmc_install
cd xbmc_install

# backup
curdate=`date '+%Y-%m-%d-%H-%M%S'`
crontab -u $username -l > .crontab
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
	/etc/vconsole.conf \
	/var/lib/transmission/.config/transmission/settings.json \
	/etc/NetworkManager/NetworkManager.conf \
	/var/www/rutorrent/conf/config.php \
	/usr/lib/X11/xorg.conf.d \
	/usr/share/alsa/cards/HDA-Intel.conf \
	/usr/share/X11/xorg.conf.d \
	/home/rtorrent/.rtorrent.rc \
	/home/${username}/.asoundrc \
	/home/${username}/.fdm.conf \
	/home/${username}/.msmtprc \
	/home/${username}/scripts/brasero.sh \
	/home/${username}/scripts/firefox.sh \
	/home/${username}/scripts/chrome.sh \
	/home/${username}/.xbmc/userdata/advancedsettings.xml \
	/home/${username}/.xbmc/userdata/guisettings.xml \
	/home/${username}/.xbmc/userdata/LCD.xml \
	/home/${username}/.xbmc/userdata/profiles.xml \
	/home/${username}/.xbmc/userdata/sources.xml \
	/home/${username}/.xbmc/userdata/RssFeeds.xml


#[ -f xbmc-pfz-0.08.tar.bz2 ] || wget "http://hencvik.googlecode.com/files/xbmc-pfz-0.08.tar.bz2"
#tar -xjvf xbmc-pfz-0.08.tar.bz2

temp_select=`mktemp 2>/dev/null` || temp_select=/tmp/test$$
#trap "rm -f $temp_select" 0 1 2 5 15

${DIALOG} --backtitle "${back_title}" --clear --title "${fg_title}" --separate-output --checklist "Select operations" 20 75 13 \
c_tz "Set timezone to Europe/Moscow" off \
i_update "Update Arch (pacman -Syu)" off \
c_net "Configure network (systemd-networkd, wpa_supplicant)" off \
i_nm "Install Network Manager" off \
i_mc "Install Midnight commander and console tools" off \
c_ddns "Configure DDNS no-ip.com script" off \
i_kodi "Install XOrg, Kodi, Fluxbox, LXDM" off \
i_plugins "Install XBMC plugins (Advanced Launcher)" off \
i_tbt "Install transmission-daemon" off \
i_onboard "Install on screen keyboard (onboard)" off \
i_ffox "Install Firefox" off \
i_chrome "Install chromium browser" off \
c_bluez "Configure bluetooth" off \
i_cyrillic "Install cyrillic for console" off \
i_httpd "Install HTTP server Apache, PHP" off \
i_frw "iptables rules add" off \
i_fdm "Install torrent control through mail" off \
c_xorg "Configure XOrg" off \
i_burn "Install burning CD/DVD software (Brasero)" off \
i_sshd "Install SSHD" off \
i_motion "Install Motion (CCTV)" off \
c_fonts "Configure fonts (MS fonts w/o antialias)" off \
i_dlna "Install MiniDLNA UPnP server" off \
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
	if ! eval "ping -c 1 archlinux.org" ; then
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
