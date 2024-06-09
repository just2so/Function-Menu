#!/bin/bash

# ����Ƿ���root�û����нű�
if [ "$(id -u)" -ne 0 ]; then
    echo "��ʹ��root�û���ͨ��sudo���д˽ű���"
    exit 1
fi

# ���°��б���װulogd2
echo "���°��б���װulogd2..."
apt-get update
apt-get install -y ulogd2

# ����ԭʼ��ulogd�����ļ�
echo "����ԭʼ��ulogd�����ļ�..."
cp /etc/ulogd.conf /etc/ulogd.conf.bak

# ����ulogd
echo "����ulogd..."
cat <<EOL > /etc/ulogd.conf
plugin="/usr/lib/ulogd/ulogd_inppkt_NFLOG.so"
plugin="/usr/lib/ulogd/ulogd_filter_IFINDEX.so"
plugin="/usr/lib/ulogd/ulogd_filter_IP2STR.so"
plugin="/usr/lib/ulogd/ulogd_filter_PRINTPKT.so"
plugin="/usr/lib/ulogd/ulogd_output_LOGEMU.so"

stack=log2:NFLOG,ip2str:IP2STR,printpkt:PRINTPKT,emu:LOGEMU

[emu-log1]
file="/var/log/ulogd.log"
sync=1
EOL

# ����iptables�����Լ�¼HTTP��HTTPS����
echo "����iptables�����Լ�¼HTTP��HTTPS����..."
iptables -A INPUT -p tcp --dport 80 -j NFLOG --nflog-prefix "HTTP_IN: "
iptables -A INPUT -p tcp --dport 443 -j NFLOG --nflog-prefix "HTTPS_IN: "
iptables -A OUTPUT -p tcp --dport 80 -j NFLOG --nflog-prefix "HTTP_OUT: "
iptables -A OUTPUT -p tcp --dport 443 -j NFLOG --nflog-prefix "HTTPS_OUT: "

if [ -f rules.v4 ]; then
# ����iptables����
	echo "����iptables����..."
	iptables-save > /etc/iptables/rules.v4
else 
	touch rules.v4
fi

# ����ulogd����
echo "����ulogd����..."
service ulogd2 restart

# ���ulogd����״̬
echo "���ulogd����״̬..."
systemctl status ulogd

# ��ʾ���
echo "������ɡ�HTTP��HTTPS������־��¼��/var/log/ulogd.log�С�"
