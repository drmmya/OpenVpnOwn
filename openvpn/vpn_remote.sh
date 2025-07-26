#!/bin/bash

#Stop script execution if any command fails
set -e

CONF_FILES_DIR_NAME=$1
protect=$2
vpn_username=$3
vpn_password=$4
vpn_port=$5
vpn_proto=$6
ssh_port=$7
username=$8

home_path="/root"
if [ "$username" != "root" ]; then
   home_path="/home/$username"
fi

CONF_FILES_DIR="$home_path/$CONF_FILES_DIR_NAME"
interface=$(. /etc/profile && ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)')

if [[ "$protect" =~ ^[yY]*$ ]]; then
   if id "$vpn_username" >/dev/null 2>&1; then
      userdel -f "$vpn_username"
   fi
   useradd -p "$(openssl passwd -1 "$vpn_password")" "$vpn_username"
   echo -e "User added successfully.\n"
fi

echo -e "==== Removing old instances ===="
apt remove -y openvpn
rm -rf /etc/openvpn
echo -e "Done\n"

echo "====== Installing OpenVPN ======"
apt -qq update && apt -qq upgrade -y
apt -qq install -y openvpn ufw
echo -e "Done\n"

echo "====== Configuring system ======"
cd ~/
sed -i "s/{interface}/$interface/" "$CONF_FILES_DIR/before.rules"
cp -rf "$CONF_FILES_DIR/before.rules" /etc/ufw/before.rules
cp -rf "$CONF_FILES_DIR/ufw" /etc/default/ufw
cp -rf "$CONF_FILES_DIR/sysctl.conf" /etc/sysctl.conf
mkdir -p /usr/lib/openvpn/
cp -rf "$CONF_FILES_DIR/openvpn-plugin-auth-pam.so" /usr/lib/openvpn/
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-openvpn.conf
sudo sysctl --system
echo -e "Done\n"

echo "====== Copying OpenVPN server files ======"
cp -rf "$CONF_FILES_DIR"/{ca.crt,server.conf,server.crt,server.key,ta.key} /etc/openvpn/
echo -e "Done\n"

echo "====== Configuring firewall ======"
ufw disable
ufw allow "$vpn_port/$vpn_proto"
ufw allow "$ssh_port/tcp"
echo -e "Done\n"

echo "====== Starting OpenVPN ======"
systemctl enable openvpn@server
systemctl start openvpn@server
status=$(systemctl show -p SubState --value openvpn@server)
echo "OpenVPN service status=$status"
echo -e "\nRebooting server..."
(
   sleep 2
   echo y | ufw enable &&
   reboot
) &
if [[ $status == "running" ]]; then exit 0; else exit 1; fi
