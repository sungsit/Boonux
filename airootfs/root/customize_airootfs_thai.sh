#!/bin/bash

set -e -u

user="boonux"

echo "Initiate pacman keyrings"
pacman-key --init
pacman-key --populate archlinux
pacman-key -r 962DDE58
pacman-key --lsign-key 962DDE58

echo "Copy /etc/skel to /root"
cp -aT /etc/skel/ /root/
chmod 700 /root
echo "root:${user}" | chpasswd -m

echo "Generate locales"
sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(th_TH\.UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=th_TH.UTF-8" > /etc/locale.conf

echo "Set local timezone to Asia/Bangkok"
ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime

sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf

echo "Adding autologin group"
! getent group autologin && groupadd -r autologin

echo "Adding nopasswdlogin group"
! getent group nopasswdlogin && groupadd -r nopasswdlogin

echo "Create ${user} with passwordless sudo"
! getent group ${user} && groupadd -g 1000 ${user}
! id ${user} && useradd -m -p "" -g ${user} -G "adm,audio,log,network,rfkill,scanner,storage,optical,power,users,wheel,autologin,nopasswdlogin" -s /usr/bin/bash ${user}
echo "${user}:${user}" | chpasswd -m
echo "${user} ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/${user}
echo "%wheel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/wheel

echo "Remove vboxclient autostart" 
if [[ -e "/etc/xdg/autostart/vboxclient.desktop" ]]; then
	rm /etc/xdg/autostart/vboxclient.desktop
fi    	

echo "Install terminix"
sudo -u ${user} yaourt --needed -S terminix

echo "Install localepurge"
sudo -u ${user} yaourt --needed -S localepurge
localepurge

#if [[ -d "/usr/share/info" ]]; then
  #find "/usr/share/info" -mindepth 1 -delete
#fi

#if [[ -d "/usr/share/man" ]]; then
  #find "/usr/share/man" -mindepth 1 -delete
#fi

# It seems the only way to set system-wide defaults is looking at /usr/share/glib-2.0/schemas/* files then recompile them all.
glib-compile-schemas /usr/share/glib-2.0/schemas/

# Enable display & network managers
systemctl enable choose-mirror.service
systemctl enable vbox-guest.service
systemctl enable lightdm.service
systemctl enable dhcpcd.service
systemctl enable NetworkManager.service
systemctl set-default graphical.target

