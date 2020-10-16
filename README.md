# [Kodi 18.5 install and configure on fresh Arch Linux installation](https://github.com/pfzim/xbmc-config/)

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

# Installation

Before you run this script you must install Arch linux as described in [official wiki](https://wiki.archlinux.org/index.php/Installation_guide) ([2](https://pingvinus.ru/note/archlinux-install)).
At step when you run `pacstrap` install additional required tools `wpa_supplicant` and `libnewt` like this:
```
pacstrap /mnt base linux linux-firmware intel-ucode wpa_supplicant libnewt lvm2 ntfs-3g git grub vim mc
```
In `arch-chroot /mnt` environment download this script:
```
cd /root
curl -O https://raw.githubusercontent.com/pfzim/xbmc-config/master/i.sh
chmod a+x i.sh
```
After complete installation and reboot, run this script:
```
cd /root
./i.sh
```

# Description

Set timezone to Europe/Moscow

Update Arch (pacman -Syu)

Configure network (systemd-networkd, wpa_supplicant, systemd-resolved)
- Wired
- Wireless (WPA, WEP, Open)
- Static
- DHCP
- Enable Wake On LAN

Install Network Manager (only if skip previous systemd-networkd step)
- For configure run `nmtui` after installation

Install Midnight commander and console tools
- Install mc man bash-completion sudo cronie vim
- Configure .inputrc

Configure DDNS no-ip.com script
- Add to crontab one line curl or wget request to no-ip.com

Install XOrg, Kodi, Fluxbox, LXDM
- Install and configure autologin and autostart Kodi

Install XBMC plugins (Advanced Launcher)
- Nothing

Install transmission-daemon
- Setup download and watch directories

Install on screen keyboard (onboard)

Install Firefox

Install chromium browser

Configure bluetooth
- Install bluez
- Discover and pair bluetooth devices

Install cyrillic for console
- Setup console fonts and Russian keyboard

Install HTTP server Apache, PHP

iptables rules add
- Configure QoS for torrent traffic is low priority, other traffic is high priority

Install torrent control through mail
- Install FDM, nail, msmtp, munpack
- Configure mailbox
- Configure FDM for fetch mail every 15 minutes
- FDM accept incomming mail with subjects:
    - control: torrent add
        - Save attached .torrent file to transmission watch directory
    - control: torrent list
        - Reply to sender information of currently transmisstion downloads
    - control: torrent alt speed on
        - Enable tranmission alt speed mode
    - control: torrent alt speed off
        - Disable tranmission alt speed mode

Configure XOrg
- Configure XOrg for my old TV with resolution 1360x768 (99-screen.conf)
- Configure Russian keyboard (99-rukbd.conf)

Install burning CD/DVD software (Brasero)

Install SSHD
- Install SSHD and configure SSHD port

Install Motion (CCTV)
- Install motion, gstreamer, v4l2loopback
- Create systemd service for create virtual video device (/dev/video9). It allow use camera separately in motion and Skype
- Configure motion write video from webcam
- Add to crontab script for rotate motion records

Configure fonts (MS fonts w/o antialias)
- Install Microsoft fonts and disable antialias

Install MiniDLNA UPnP server
- Install and configure MiniDLNA to share directory with torrents
