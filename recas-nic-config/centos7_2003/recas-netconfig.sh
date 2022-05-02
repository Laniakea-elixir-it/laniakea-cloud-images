#!/usr/bin/env bash


ETH0_IFCFG_FILE='/etc/sysconfig/network-scripts/ifcfg-eth0'
ETH1_IFCFG_FILE='/etc/sysconfig/network-scripts/ifcfg-eth1'


# Read BOOTPROTO value from ifcfg-eth0
function read_bootproto_eth0() {
  BOOTPROTO=$(awk -F= '$1 ~ /BOOTPROTO/ {print $2}' $ETH0_IFCFG_FILE)
}


# Swap ifcfg-eth0 and ifcfg-eth1
function swap_ifcfg() {
  mv $ETH0_IFCFG_FILE $ETH1_IFCFG_FILE -b -S .old
  mv $ETH1_IFCFG_FILE.old $ETH0_IFCFG_FILE
}


# Set BOOTPROTO=static for public network in ifcfg-eth1
function set_bootproto_static() {
  sed -i '/^BOOTPROTO/s/=.*$/=static/' $ETH1_IFCFG_FILE  
}



#________________________________
#________________________________
# Main script

# Check if ifcfg-eth1 file exists
if [ -f $ETH1_IFCFG_FILE ]; then
  # Read BOOTPROTO value from ifcfg-eth0
  read_bootproto_eth0

  # If ifcfg-eth0 has BOOTPROTO=none, it's configured for public network.
  # eth0 needs to be configured for private network and eth1 for public network
  if [ $BOOTPROTO == 'none' ]; then
    # Set eth0 for private network and eth1 for public network
    swap_ifcfg

  fi

  # Set BOOTPROTO=static for public network in ifcfg-eth1
  set_bootproto_static
  
  # Restart network
  systemctl restart network

fi
