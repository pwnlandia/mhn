#!/bin/bash

# clear out any old rules so this is idempotent
iptables --flush
iptables --table nat --flush

iptables --append INPUT --in-interface eth0 --proto tcp --dport 1:21 --jump DROP
iptables --append INPUT --in-interface eth0 --proto tcp --dport 23:1024 --jump DROP

# allow 22
for PORT in 3000 8000 8080 8098 9001 11211; do
    iptables --append INPUT --in-interface eth0 --proto tcp --sport $PORT --jump DROP
done

# print out current rules to check correctness
iptables --list --numeric
