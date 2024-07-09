#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractiv

SS_PORT=58388
SS_METHOD=chacha20-ietf-poly1305

apt update -y
apt upgrade -y
apt install -y shadowsocks-libev qrencode

HOME_DIR=`eval echo ~$SUDO_USER`
DEF_IFACE=`ip r | grep default | head -1 |  cut -f 5 -d ' '`
MYIP=`ip a show dev $DEF_IFACE | grep -Eo 'inet.*brd' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'`
PASSWD_LEN=12
SS_PASSWD=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "$PASSWD_LEN" | head -n 1)
URI=`echo -n "$SS_METHOD:$SS_PASSWD@$MYIP:$SS_PORT" | base64 | tr -d '='`
URI=ss://$URI
echo $URI > $HOME_DIR/ss.uri

# server config
cat > /etc/shadowsocks-libev/config.json << eof
{
    "server":["0.0.0.0"],
    "mode":"tcp_and_udp",
    "server_port":$SS_PORT,
    "local_port":1080,
    "password":"$SS_PASSWD",
    "timeout":60,
    "method":"$SS_METHOD"
}
eof

# Client config
cat > $HOME_DIR/client.json << eof
{
    "server":"$MYIP",
    "mode":"tcp_and_udp",
    "server_port":$SS_PORT,
    "local_port":1080,
    "password":"$SS_PASSWD",
    "timeout":60,
    "method":"$SS_METHOD"
}
eof

systemctl daemon-reload
systemctl enable --now shadowsocks-libev.service
systemctl restart shadowsocks-libev.service

echo 
echo '**************************************************'
echo '* Shadowsocks server was installed successfully! *'
echo '*                                                *'
echo "* you client configs: 'client.json' and 'ss.uri' *"
echo '**************************************************'
echo 
