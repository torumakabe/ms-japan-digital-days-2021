#!/bin/bash
sudo tc qdisc add dev eth0 root handle 1: prio
sudo tc filter add dev eth0 protocol ip parent 1: prio 2 u32 match ip dst 0.0.0.0/0 flowid 1:2

sudo tc qdisc add dev eth0 parent 1:1 handle 10: netem loss 100%
sudo tc filter add dev eth0 protocol ip parent 1: prio 1 u32 match ip dport 8888 0xffff flowid 1:1
