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

#Guide: http://lcdev.dk/2012/11/18/raspberry-pi-tutorial-connect-to-wifi-or-create-an-encrypted-dhcp-enabled-ad-hoc-network-as-fallback/
#Edit /etc/dhcp/dhcpd.conf
sudo echo "
DHCPDARGS=wlan0; #args for the dhcpd daemon -> limit DHCP to the wlan0 interface
ddns-update-style interim;

default-lease-time 600;
max-lease-time 7200;

authoritative;
log-facility local7;

option subnet-mask 255.255.255.0;
option broadcast-address 192.168.1.255;
option domain-name "RPi-network";
option routers 192.168.1.1; #default gateway

subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.2 192.168.1.20; #IP range to offer
}

#static IP-assignment
host Phone {
    hardware ethernet 11:aa:22:bb:33:cc;
    192.168.1.100;
}

host PC {
    hardware ethernet 11:aa:22:bb:33:cd;
    192.168.1.101;
}
" >> /etc/dhcp/dhcpd.conf

#where N should be replaced by your target line number ====================> Find correct line number
sed -i 'Ns/.*/INTERFACES="wlan0"/' /etc/default/isc-dhcp-server

#Create backup
sudo cp /etc/rc.local /etc/rc.local.bck
#Clean original /etc/rc.local
sudo truncate -s 0 /etc/rc.local

# RPi Network Conf Bootstrapper ====================> Edit with full script
sudo echo "
createAdHocNetwork(){
    echo "Creating ad-hoc network"
    ifconfig wlan0 down
    iwconfig wlan0 mode ad-hoc
    iwconfig wlan0 key aaaaa11111 #WEP key
    iwconfig wlan0 essid PiAdHoc      #SSID
    ifconfig wlan0 192.168.1.200 netmask 255.255.255.0 up
    /usr/sbin/dhcpd wlan0
    echo "Ad-hoc network created"
}
 
echo "================================="
echo "RPi Network Conf Bootstrapper 0.1"
echo "================================="
echo "Scanning for known WiFi networks"
ssids=( 'MyWlan' 'MyOtherWlan' )        # =================== Can be edited ===================
connected=false
for ssid in "${ssids[@]}"
do
    if iwlist wlan0 scan | grep $ssid > /dev/null
    then
        echo "First WiFi in range has SSID:" $ssid
        echo "Starting supplicant for WPA/WPA2"
        wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null 2>&1
        echo "Obtaining IP from DHCP"
        if dhclient -1 wlan0
        then
            echo "Connected to WiFi"
            connected=true
            break
        else
            echo "DHCP server did not respond with an IP lease (DHCPOFFER)"
            wpa_cli terminate
            break
        fi
    else
        echo "Not in range, WiFi with SSID:" $ssid
    fi
done
 
if ! $connected; then
    createAdHocNetwork
fi
 
exit 0
" >> /etc/rc.local











#Reboot to make everything working
sudo reboot
