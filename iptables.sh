#!/bin/sh

# iptables script generated 2017-04-28
# http://www.mista.nu/iptables

IPT="/sbin/iptables"

# Flush old rules, old custom tables
$IPT --flush
$IPT --delete-chain

$IPT -t nat --flush
$IPT -t nat --delete-chain

# Enable free use of loopback interfaces
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

# All TCP sessions should begin with SYN
$IPT -A INPUT -p tcp ! --syn -m state --state NEW -s 0.0.0.0/0 -j DROP

# OVH IPs
$IPT -A INPUT -i eth0 --source 92.222.184.0/24 -j ACCEPT
$IPT -A INPUT -i eth0 --source 92.222.185.0/24 -j ACCEPT
$IPT -A INPUT -i eth0 --source 92.222.186.0/24 -j ACCEPT
$IPT -A INPUT -i eth0 --source 167.114.37.0/24 -j ACCEPT
$IPT -A INPUT -i eth0 --source 198.100.154.2/32 -j ACCEPT

# Accept inbound TCP packets
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT -p tcp --dport 21 -m tcp -j ACCEPT
$IPT -A INPUT -p tcp --dport 22 -m tcp -j ACCEPT
$IPT -A INPUT -p tcp --dport 80 -m tcp -j ACCEPT
$IPT -A INPUT -p tcp --dport 443 -m tcp -j ACCEPT

# FTPd passive
$IPT -A INPUT -p tcp --match multiport --dports 57000:58000 -j ACCEPT

# Accept inbound ICMP messages
$IPT -A INPUT -p icmp -m icmp --icmp-type 3 -j ACCEPT
$IPT -A INPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
$IPT -A INPUT -p icmp -m icmp --icmp-type 11 -j ACCEPT
$IPT -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT

# Set default policies for all three default chains
$IPT -P INPUT DROP
$IPT -P FORWARD DROP
$IPT -P OUTPUT ACCEPT

# OPENVPN
$IPT -A INPUT -i tun+ -j ACCEPT

$IPT -A FORWARD -i tun+ -j ACCEPT
$IPT -A FORWARD -i tun+ -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -i eth0 -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT

$IPT -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
$IPT -A INPUT -p udp --dport 1194 -m udp -j ACCEPT
