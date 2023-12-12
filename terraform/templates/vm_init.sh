#!/bin/bash

echo "Port 22" >> /etc/ssh/sshd_config
systemctl restart sshd
