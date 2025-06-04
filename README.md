# [Installing and configuring Kodi on a fresh Arch Linux System](https://github.com/pfzim/xbmc-config/)

This script is a comprehensive setup tool for configuring an Arch Linux system specifically tailored for use with Kodi (formerly XBMC). It provides a menu-driven interface to install and configure various components needed for a media center setup.

Install Arch Linux as described in official instruction
Download `i.sh` script and run it
```
wget https://raw.githubusercontent.com/pfzim/xbmc-config/master/i.sh
chmod a+rx i.sh
sudo ./i.sh
```

![screenshot](https://raw.githubusercontent.com/pfzim/other/master/screenshot_xbmc_config.png)

## Script Overview

The script performs the following main functions:

1. **System Configuration**
   - Sets timezone to Europe/Moscow
   - Updates Arch Linux packages (`pacman -Syu`)
   - Configures network interfaces (both wired and wireless)
   - Installs and configures console tools (Midnight Commander, bash completion)
   - Sets up Cyrillic support for console

2. **Media Center Components**
   - Installs Kodi along with its dependencies (XOrg, Fluxbox window manager, LXDM display manager)
   - Configures autologin and automatic Kodi startup
   - Sets up UPnP media sharing with MiniDLNA
   - Configures Transmission torrent client with customizable download directories

3. **Network Services**
   - Configures SSH server with customizable port
   - Sets up dynamic DNS (no-ip.com) for remote access
   - Configures firewall rules with QoS for torrent traffic
   - Implements email-based torrent control system

4. **Additional Features**
   - Bluetooth device configuration
   - Web browser installation (Firefox or Chromium)
   - On-screen keyboard setup
   - CD/DVD burning software (Brasero)
   - CCTV functionality with Motion

# XBMC 13 post install configuration (old version)

Boot XBMCbuntu, CTRL+ALT+F1, login and run:
```
wget https://raw.githubusercontent.com/pfzim/xbmc-config/master/i-xbmcubuntu.sh
chmod a+rx i-xbmcubuntu.sh
sudo ./i-xbmcubuntu.sh
```

# Installation

Install Arch Linux following the [official wiki guide](https://wiki.archlinux.org/index.php/Installation_guide) ([alternative guide](https://pingvinus.ru/note/archlinux-install)).
During installation, when running `pacstrap`, include additional packages (`wpa_supplicant` and `libnewt`) like this:
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

## Technical Details

The script uses:
- `whiptail` for menu-driven interface
- Systemd for service management
- Networkd for network configuration (with optional NetworkManager)
- Crontab for scheduled tasks
- Various configuration files in `/etc` for persistent settings

The script maintains a backup of all modified configuration files in a timestamped archive before making changes.

## Notes

- The script is designed to be run as root
- It checks for required dependencies before execution
- Each configuration section can be selected individually through the menu interface
- The script provides verification prompts for critical configuration items
- Network configuration requires internet access for package installation

This script provides a complete solution for setting up a feature-rich media center based on Arch Linux and Kodi, with particular attention to Russian language support and remote management capabilities.
