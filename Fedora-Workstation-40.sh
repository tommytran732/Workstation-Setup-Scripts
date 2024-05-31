#!/bin/bash

# Copyright (C) 2021-2024 Thien Tran
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

#Please note that this is how I PERSONALLY setup my computer - I do some stuff such as not using anything to download GNOME extensions from extensions.gnome.org and installing the extensions as a package instead

output(){
    echo -e '\e[36m'"$1"'\e[0m';
}

unpriv(){
    sudo -u nobody "$@"
}

virtualization=$(systemd-detect-virt)

# Increase compression level
sudo sed -i 's/zstd:1/zstd/g' /etc/fstab

# Compliance
sudo systemctl mask debug-shell.service
sudo systemctl mask kdump.service

# Setting umask to 077
umask 077
sudo sed -i 's/^UMASK.*/UMASK 077/g' /etc/login.defs
sudo sed -i 's/^HOME_MODE/#HOME_MODE/g' /etc/login.defs
sudo sed -i 's/^USERGROUPS_ENAB.*/USERGROUPS_ENAB no/g' /etc/login.defs
sudo sed -i 's/umask 022/umask 077/g' /etc/bashrc

# Make home directory private
sudo chmod 700 /home/*

# Setup NTS
if [ "${virtualization}" = 'parallels' ]; then
    sudo dnf -y remove chrony
else
    sudo rm -rf /etc/chrony.conf
    unpriv curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/chrony.conf | sudo tee /etc/chrony.conf
    unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/sysconfig/chronyd | sudo tee /etc/sysconfig/chronyd

    sudo systemctl restart chronyd
fi

# Remove nullok
sudo /usr/bin/sed -i 's/\s+nullok//g' /etc/pam.d/system-auth

# Harden SSH
unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/ssh/ssh_config.d/10-custom.conf | sudo tee /etc/ssh/ssh_config.d/10-custom.conf
sudo chmod 644 /etc/ssh/ssh_config.d/10-custom.conf

# Security kernel settings
unpriv curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/modprobe.d/30_security-misc.conf | sudo tee /etc/modprobe.d/30_security-misc.conf
sudo chmod 644 /etc/modprobe.d/30_security-misc.conf
sudo sed -i 's/#install msr/install msr/g' /etc/modprobe.d/30_security-misc.conf
unpriv curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/usr/lib/sysctl.d/990-security-misc.conf | sudo tee /etc/sysctl.d/990-security-misc.conf
sudo chmod 644 /etc/sysctl.d/990-security-misc.conf
sudo sed -i 's/kernel.yama.ptrace_scope.*/kernel.yama.ptrace_scope=3/g' /etc/sysctl.d/990-security-misc.conf
unpriv curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/usr/lib/sysctl.d/30_silent-kernel-printk.conf | sudo tee /etc/sysctl.d/30_silent-kernel-printk.conf
sudo chmod 644 /etc/sysctl.d/30_silent-kernel-printk.conf
unpriv curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/usr/lib/sysctl.d/30_security-misc_kexec-disable.conf | sudo tee /etc/sysctl.d/30_security-misc_kexec-disable.conf
sudo chmod 644 /etc/sysctl.d/30_security-misc_kexec-disable.conf
sudo dracut -f
sudo sysctl -p

if sudo bootctl status | grep -q systemd-boot; then
    if [ "${virtualization}" = 'parallels' ]; then
        sudo sed -i 's/quiet root/quiet mitigations=auto,nosmt spectre_v2=on spectre_bhi=on spec_store_bypass_disable=on tsx=off kvm.nx_huge_pages=force nosmt=force l1d_flush=on spec_rstack_overflow=safe-ret gather_data_sampling=force reg_file_data_sampling=on random.trust_bootloader=off random.trust_cpu=off intel_iommu=on amd_iommu=force_isolation efi=disable_early_pci_dma iommu=force iommu.passthrough=0 iommu.strict=1 slab_nomerge init_on_alloc=1 init_on_free=1 pti=on vsyscall=none ia32_emulation=0 page_alloc.shuffle=1 randomize_kstack_offset=on debugfs=off root/g' /etc/kernel/cmdline
    else 
        sudo sed -i 's/quiet root/quiet mitigations=auto,nosmt spectre_v2=on spectre_bhi=on spec_store_bypass_disable=on tsx=off kvm.nx_huge_pages=force nosmt=force l1d_flush=on spec_rstack_overflow=safe-ret gather_data_sampling=force reg_file_data_sampling=on random.trust_bootloader=off random.trust_cpu=off intel_iommu=on amd_iommu=force_isolation efi=disable_early_pci_dma iommu=force iommu.passthrough=0 iommu.strict=1 slab_nomerge init_on_alloc=1 init_on_free=1 pti=on vsyscall=none ia32_emulation=0 page_alloc.shuffle=1 randomize_kstack_offset=on debugfs=off lockdown=confidentiality module.sig_enforce=1 root/g' /etc/kernel/cmdline
    fi
    sudo dnf reinstall -y kernel-core
else
    if [ "${virtualization}" = 'parallels' ]; then
        sudo grubby --update-kernel=ALL --args='mitigations=auto,nosmt spectre_v2=on spectre_bhi=on spec_store_bypass_disable=on tsx=off kvm.nx_huge_pages=force nosmt=force l1d_flush=on spec_rstack_overflow=safe-ret gather_data_sampling=force reg_file_data_sampling=on random.trust_bootloader=off random.trust_cpu=off intel_iommu=on amd_iommu=force_isolation efi=disable_early_pci_dma iommu=force iommu.passthrough=0 iommu.strict=1 slab_nomerge init_on_alloc=1 init_on_free=1 pti=on vsyscall=none ia32_emulation=0 page_alloc.shuffle=1 randomize_kstack_offset=on debugfs=off'
    else
        sudo grubby --update-kernel=ALL --args='mitigations=auto,nosmt spectre_v2=on spectre_bhi=on spec_store_bypass_disable=on tsx=off kvm.nx_huge_pages=force nosmt=force l1d_flush=on spec_rstack_overflow=safe-ret gather_data_sampling=force reg_file_data_sampling=on random.trust_bootloader=off random.trust_cpu=off intel_iommu=on amd_iommu=force_isolation efi=disable_early_pci_dma iommu=force iommu.passthrough=0 iommu.strict=1 slab_nomerge init_on_alloc=1 init_on_free=1 pti=on vsyscall=none ia32_emulation=0 page_alloc.shuffle=1 randomize_kstack_offset=on debugfs=off lockdown=confidentiality module.sig_enforce=1'
    fi
fi

# Disable coredump
unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/security/limits.d/30-disable-coredump.conf | sudo tee /etc/security/limits.d/30-disable-coredump.conf

# Disable XWayland
umask 022
sudo mkdir -p /etc/systemd/user/org.gnome.Shell@wayland.service.d
unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/systemd/user/org.gnome.Shell%40wayland.service.d/override.conf | sudo tee /etc/systemd/user/org.gnome.Shell@wayland.service.d/override.conf
umask 077

# Setup dconf
umask 022
mkdir -p /etc/dconf/db/local.d/locks

unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/locks/automount-disable | sudo tee /etc/dconf/db/local.d/locks/automount-disable
unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/locks/privacy | sudo tee /etc/dconf/db/local.d/locks/privacy

unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/adw-gtk3-dark | sudo tee /etc/dconf/db/local.d/adw-gtk3-dark
unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/automount-disable | sudo tee /etc/dconf/db/local.d/automount-disable
unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/button-layout | sudo tee /etc/dconf/db/local.d/button-layout
unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/prefer-dark | sudo tee /etc/dconf/db/local.d/prefer-dark
unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/privacy | sudo tee /etc/dconf/db/local.d/privacy
unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/touchpad | sudo tee /etc/dconf/db/local.d/touchpad

sudo dconf update
umask 077

# Setup ZRAM
unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/systemd/zram-generator.conf | sudo tee /etc/systemd/zram-generator.conf

# Setup DNF
unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dnf/dnf.conf | sudo tee /etc/dnf/dnf.conf
sudo sed -i 's/^metalink=.*/&\&protocol=https/g' /etc/yum.repos.d/*

# Remove firefox packages
sudo dnf -y remove fedora-bookmarks fedora-chromium-config firefox mozilla-filesystem

# Remove Network + hardware tools packages
sudo dnf -y remove avahi cifs* '*cups' dmidecode dnsmasq geolite2* mtr net-snmp-libs net-tools nfs-utils nmap-ncat nmap-ncat opensc openssh-server rsync rygel sgpio tcpdump teamd traceroute usb_modeswitch

# Remove support for some languages and spelling
sudo dnf -y remove '*anthy*' '*hangul*' ibus-typing-booster '*m17n*' '*pinyin*' '*speech*' texlive-libs words '*zhuyin*'

# Remove codec + image + printers
sudo dnf -y remove openh264 ImageMagick* sane* simple-scan

# Remove Active Directory + Sysadmin + reporting tools
sudo dnf -y remove 'sssd*' realmd cyrus-sasl-gssapi quota* dos2unix kpartx sos samba-client gvfs-smb

# Remove vm and virtual stuff
sudo dnf -y remove 'podman*' '*libvirt*' 'open-vm*' qemu-guest-agent 'hyperv*' spice-vdagent virtualbox-guest-additions vino xorg-x11-drv-vmware xorg-x11-drv-amdgpu

# Remove NetworkManager
sudo dnf -y remove NetworkManager-pptp-gnome NetworkManager-ssh-gnome NetworkManager-openconnect-gnome NetworkManager-openvpn-gnome NetworkManager-vpnc-gnome ppp* ModemManager

# Remove Gnome apps
sudo dnf remove -y baobab chrome-gnome-shell eog gnome-boxes gnome-calculator gnome-calendar gnome-characters gnome-classic* gnome-clocks gnome-color-manager gnome-connections \
    gnome-contacts gnome-disk-utility gnome-font-viewer gnome-logs gnome-maps gnome-photos gnome-remote-desktop gnome-screenshot gnome-shell-extension-apps-menu \
    gnome-shell-extension-background-logo gnome-shell-extension-launch-new-instance gnome-shell-extension-places-menu gnome-shell-extension-window-list gnome-text-editor \
    gnome-themes-extra gnome-tour gnome-user* gnome-weather loupe snapshot totem

# Remove apps
sudo dnf remove -y abrt cheese evince file-roller* libreoffice* mediawriter rhythmbox yelp

# Remove other packages
 sudo dnf remove -y lvm2 rng-tools thermald '*perl*' yajl

# Disable openh264 repo
sudo dnf config-manager --set-disabled fedora-cisco-openh264

# Update packages
sudo dnf -y upgrade

# Install packages that I use
sudo dnf -y install adw-gtk3-theme gnome-console gnome-shell-extension-appindicator gnome-shell-extension-blur-my-shell gnome-shell-extension-background-logo

# Install appropriate virtualization drivers
if [ "$virtualization" = 'kvm' ]; then
    sudo dnf install -y qemu-guest-agent spice-vdagent
fi

# Setup Flatpak
sudo flatpak override --system --nosocket=x11 --nosocket=fallback-x11 --nosocket=pulseaudio --nosocket=session-bus --nosocket=system-bus --unshare=network --unshare=ipc --nofilesystem=host:reset --nodevice=input --nodevice=shm --nodevice=all --no-talk-name=org.freedesktop.Flatpak --no-talk-name=org.freedesktop.systemd1 --no-talk-name=ca.desrt.dconf --no-talk-name=org.gnome.Shell.Extensions
flatpak override --user --nosocket=x11 --nosocket=fallback-x11 --nosocket=pulseaudio --nosocket=session-bus --nosocket=system-bus --unshare=network --unshare=ipc --nofilesystem=host:reset --nodevice=input --nodevice=shm --nodevice=all --no-talk-name=org.freedesktop.Flatpak --no-talk-name=org.freedesktop.systemd1 --no-talk-name=ca.desrt.dconf --no-talk-name=org.gnome.Shell.Extensions
flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak --user install org.gnome.Extensions com.github.tchx84.Flatseal org.gnome.Loupe -y
flatpak --user override com.github.tchx84.Flatseal --filesystem=/var/lib/flatpak/app:ro --filesystem=xdg-data/flatpak/app:ro --filesystem=xdg-data/flatpak/overrides:create
flatpak --user override org.gnome.Extensions --talk-name=org.gnome.Shell.Extensions
flatpak update -y

# Install Microsoft Edge if x86_64
MACHINE_TYPE=$(uname -m)
if [ "${MACHINE_TYPE}" == 'x86_64' ]; then
    umask 022
    output 'x86_64 machine, installing Microsoft Edge.'
    echo '[microsoft-edge]
name=microsoft-edge
baseurl=https://packages.microsoft.com/yumrepos/edge/
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc' | sudo tee /etc/yum.repos.d/microsoft-edge.repo
    sudo dnf install -y microsoft-edge-stable
    sudo mkdir -p /etc/opt/edge/policies/managed/ /etc/opt/edge/policies/recommended/
    unpriv curl https://raw.githubusercontent.com/TommyTran732/Microsoft-Edge-Policies/main/Linux/managed.json | sudo tee /etc/opt/edge/policies/managed/managed.json
    unpriv curl https://raw.githubusercontent.com/TommyTran732/Microsoft-Edge-Policies/main/Linux/recommended.json | sudo tee /etc/opt/edge/policies/recommended/recommended.json
    sudo mkdir -p /usr/local/share/applications
    sed 's/^Exec=\/usr\/bin\/microsoft-edge-stable/& --ozone-platform=wayland --start-maximized/g' /usr/share/applications/microsoft-edge.desktop | sudo tee /usr/local/share/applications/microsoft-edge.desktop
    umask 077
fi

# Setup fwupd
echo 'UriSchemes=file;https' | sudo tee -a /etc/fwupd/fwupd.conf
sudo systemctl restart fwupd

# Enable auto TRIM
sudo systemctl enable fstrim.timer

### Differentiating bare metal and virtual installs

# Setup tuned
if [ "$virtualization" = 'none' ]; then
    output "Bare Metal installation. Tuned will not be set up here - PPD should take care of it."
else
    sudo dnf remove -y power-profiles-daemon
    sudo dnf install -y tuned
    sudo systemctl enable --now tuned
    sudo tuned-adm profile virtual-guest
fi

# Setup real-ucode and hardened_malloc
if [ "$virtualization" = 'none' ] || [ "${MACHINE_TYPE}" == 'x86_64' ]; then
    sudo dnf install -y 'https://divested.dev/rpm/fedora/divested-release-20231210-2.noarch.rpm'
    sudo sed -i 's/^metalink=.*/&?protocol=https/g' /etc/yum.repos.d/divested-release.repo
    if [ "${MACHINE_TYPE}" != 'x86_64' ]; then
        sudo dnf config-manager --save --setopt=divested.includepkgs=divested-release,real-ucode,microcode_ctl,amd-ucode-firmware
        sudo dnf install -y real-ucode
        sudo dracut -f
    elif [ "$virtualization" != 'none' ]; then
        sudo dnf config-manager --save --setopt=divested.includepkgs=divested-release,hardened_malloc
        sudo dnf install -y hardened_malloc
    else
        sudo dnf config-manager --save --setopt=divested.includepkgs=divested-release,real-ucode,microcode_ctl,amd-ucode-firmware,hardened_malloc
        sudo dnf install -y real-ucode hardened_malloc
        echo 'libhardened_malloc.so' | sudo tee /etc/ld.so.preload
        sudo dracut -f
    fi
elif [ "${MACHINE_TYPE}" == 'aarch64' ]; then
    sudo dnf copr enable secureblue/hardened_malloc -y
    sudo dnf install -y hardened_malloc
fi

# Setup networking
sudo firewall-cmd --set-default-zone=block
sudo firewall-cmd --permanent --add-service=dhcpv6-client
sudo firewall-cmd --reload
sudo firewall-cmd --lockdown-on

unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/NetworkManager/conf.d/00-macrandomize.conf | sudo tee /etc/NetworkManager/conf.d/00-macrandomize.conf
unpriv curl https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/NetworkManager/conf.d/01-transient-hostname.conf | sudo tee /etc/NetworkManager/conf.d/01-transient-hostname.conf
sudo nmcli general reload conf
sudo hostnamectl hostname 'localhost'
sudo hostnamectl --transient hostname ''

sudo mkdir -p /etc/systemd/system/NetworkManager.service.d
unpriv curl https://gitlab.com/divested/brace/-/raw/master/brace/usr/lib/systemd/system/NetworkManager.service.d/99-brace.conf | sudo tee /etc/systemd/system/NetworkManager.service.d/99-brace.conf
sudo systemctl daemon-reload
sudo systemctl restart NetworkManager

output 'The script is done. You can also remove gnome-terminal since gnome-console will replace it.'