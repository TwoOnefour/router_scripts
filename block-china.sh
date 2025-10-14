#!/usr/bin/env bash

# Create the ipset list
ipset -N china hash:net

# remove any old list that might exist from previous runs of this script
rm -rf /root/cn.zone

# Pull the latest IP set for China
wget -P /root http://www.ipdeny.com/ipblocks/data/countries/cn.zone

# Add each IP address from the downloaded list into the ipset 'china'
for i in $(cat /root/cn.zone ); do ipset -A china $i; done

# block chinese connection by set rule
iptables -A INPUT -p tcp -m set --match-set china src -j DROP