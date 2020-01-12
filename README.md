# Kodi 18.5 install and configure on fresh Arch Linux installation

Install Arch Linux as described in official instruction
Download `i.sh` script and run it
```
wget https://raw.githubusercontent.com/pfzim/xbmc-config/master/i.sh
chmod a+rx i.sh
sudo ./i.sh
```

# XBMC 13 post install configuration (old version)

Boot XBMCbuntu, CTRL+ALT+F1, login and run:
```
wget https://raw.githubusercontent.com/pfzim/xbmc-config/master/i-xbmcubuntu.sh
chmod a+rx i-xbmcubuntu.sh
sudo ./i-xbmcubuntu.sh
```

Set timezone to Europe/Moscow
Update Arch (pacman -Syu)
Configure network (systemd-networkd, wpa_supplicant, systemd-resolved)
Install Network Manager
Install Midnight commander and console tools
Configure DDNS no-ip.com script
Install XOrg, Kodi, Fluxbox, LXDM
Install XBMC plugins (Advanced Launcher)
Install transmission-daemon
Install on screen keyboard (onboard)
Install Firefox
Install chromium browser
Configure bluetooth
Install cyrillic for console
Install HTTP server Apache, PHP
iptables rules add
Install torrent control through mail
Configure XOrg
Install burning CD/DVD software (Brasero)
Install SSHD
Install Motion (CCTV)
Configure fonts (MS fonts w/o antialias)
Install MiniDLNA UPnP server
