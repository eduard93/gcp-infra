#!/bin/bash

export SSH_PORT=2180

sed -i "s/^#Port.*/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
systemctl restart sshd
semanage port -a -t ssh_port_t -p tcp ${SSH_PORT}
