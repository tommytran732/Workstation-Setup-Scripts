#!/bin/bash
#Assuming that you are using ANSSI-BP-028

mkdir -p /etc/ssh/ssh_config.d /etc/ssh/sshd_config.d 
echo "GSSAPIAuthentication no" | sudo tee -a /etc/ssh/ssh_config.d/10-custom.conf
echo "X11Forwarding no 
GSSAPIAuthentication no" | sudo tee -a /etc/ssh/sshd_config.d/10-custom.conf
echo "PasswordAuthentication no" | sudo tee /etc/ssh/sshd_config.d/40-disable-passwords.conf

sudo dnf install tuned -y
sudo tuned-adm profile virtual-guest

sudo curl https://raw.githubusercontent.com/Whonix/security-misc/master/etc/modprobe.d/30_security-misc.conf -o /etc/modprobe.d/30_security-misc.conf
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/sysctl.d/30_security-misc.conf -o /etc/sysctl.d/30_security-misc.conf
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/sysctl.d/30_silent-kernel-printk.conf -o /etc/sysctl.d/30_silent-kernel-printk.conf
sudo curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/chrony.conf -o /etc/chrony.conf
sed -i 's/kernel.yama.ptrace_scope=2/kernel.yama.ptrace_scope=3/g' /etc/sysctl.d/30_security-misc.conf