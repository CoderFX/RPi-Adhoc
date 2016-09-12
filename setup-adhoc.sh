#!/bin/bash

#Create backups
sudo cp /etc/network/interfaces /etc/network/interfaces.bck
sudo cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.bck

#Clean original files:
sudo truncate -s 0 /etc/network/interfaces
sudo truncate -s 0 /etc/wpa_supplicant/wpa_supplicant.conf

#Change settings to Adhoc in /etc/network/interfaces
sudo echo "
# interfaces(5) file used by ifup(8) and ifdown(8)

# Please note that this file is written to be used with dhcpcd
# For static IP, consult /etc/dhcpcd.conf and 'man dhcpcd.conf'

# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

iface eth0 inet dhcp

auto wlan0
iface wlan0 inet static
  address 192.168.1.1
  netmask 255.255.255.0
  wireless-channel 1
  wireless-essid PiAdHoc
  wireless-mode ad-hoc
  
#2nd wifi with wifi dongle
#auto wlan1
#iface wlan1 inet dhcp
" >> /etc/network/interfaces

#Install DHCP server. Guide: http://slicepi.com/creating-an-ad-hoc-network-for-your-raspberry-pi/
sudo apt-get install isc-dhcp-server -y

#Create backup
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bck

#Clean /etc/dhcp/dhcpd.conf
sudo truncate -s 0 /etc/dhcp/dhcpd.conf

#Edit /etc/dhcp/dhcpd.conf
sudo echo "
ddns-update-style interim;
default-lease-time 600;
max-lease-time 7200;
authoritative;
log-facility local7;
subnet 192.168.1.0 netmask 255.255.255.0 {
 range 192.168.1.5 192.168.1.150;
}
" >> /etc/dhcp/dhcpd.conf

#Reboot to make everything working
sudo reboot













