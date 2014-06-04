#!/bin/bash
# -*- ENCODING: UTF-8 -*-

iptables -I FORWARD -p tcp -d 172.16.0.101 --dport 80 -j ACCEPT
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 172.16.0.102:80

iptables -I FORWARD -p tcp -d 172.16.0.101 --dport 443 -j ACCEPT
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j DNAT --to-destination 172.16.0.101:443

iptables -I FORWARD -p tcp -d 172.16.0.102 --dport 135 -j ACCEPT
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 135 -j DNAT --to-destination 172.16.0.102:135

iptables -I FORWARD -p tcp -d 172.16.0.102 --dport 139 -j ACCEPT
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 139 -j DNAT --to-destination 172.16.0.102:139

iptables -I FORWARD -p tcp -d 172.16.0.102 --dport 445 -j ACCEPT
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 445 -j DNAT --to-destination 172.16.0.102:445

iptables -I FORWARD -p tcp -d 172.16.0.102 --dport 1025 -j ACCEPT
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 1025 -j DNAT --to-destination 172.16.0.102:1025

iptables -I FORWARD -p tcp -d 172.16.0.102 --dport 5000 -j ACCEPT
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 5000 -j DNAT --to-destination 172.16.0.102:5000

iptables -I FORWARD -p tcp -d 172.16.0.103 --dport 3389 -j ACCEPT
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 3389 -j DNAT --to-destination 172.16.0.103:3389

#iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
iptables-save
exit
