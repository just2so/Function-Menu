#!/bin/bash
export LANG=en_US.UTF-8

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

#�������ر���
file_path="/etc/ulogd.conf.bak"

# �ļ������ھʹ���
if [ ! -f "$file_path" ]; then
    touch "$file_path"
    if [ $? -ne 0 ]; then
        echo "����ʧ��"
        exit 1
    fi
fi

 # ����ԭʼ��ulogd�����ļ�
echo "����ԭʼ��ulogd�����ļ�..."
cp /etc/ulogd.conf /etc/ulogd.conf.bak

# ����ulogd����
echo "����ulogd����..."
systemctl restart ulogd2

# �ȴ�һ��ʱ�䣬ȷ�������������
sleep 5

#!/bin/bash

# �ҳ� ulogd2 ���̵� PID
ulogd_pid=$(ps aux | grep ulogd | grep -v grep | awk '{print $2}')

if [ -n "$ulogd_pid" ]; then
    echo "ulogd2 ���̵� PID ��: $ulogd_pid"
    
    # ���� PID �ļ�·��
    pid_file="/run/ulog/ulogd.pid"
    pid_dir=$(dirname "$pid_file")
    
    # ���Ŀ¼�Ƿ���ڣ�����������򴴽�
    if [ ! -d "$pid_dir" ]; then
        mkdir -p "$pid_dir"
        if [ $? -ne 0 ]; then
            echo "�޷�����Ŀ¼: $pid_dir"
            exit 1
        fi
    fi
    
    # ɾ���Ѵ��ڵ� PID �ļ�
    if [ -f "$pid_file" ]; then
        rm "$pid_file"
        if [ $? -ne 0 ]; then
            echo "�޷�ɾ���Ѵ��ڵ��ļ�: $pid_file"
            exit 1
        fi
    fi
    
    # ���� PID �ļ���д�� PID
    touch "$pid_file"
    echo "$ulogd_pid" | sudo tee "$pid_file" > /dev/null
    
    if [ $? -ne 0 ]; then
        echo "PID �ļ�����ʧ��"
        exit 1
    else
        echo "PID �ļ������ɹ�: $pid_file"
    fi
else
    echo "δ�ҵ� ulogd2 ����"
    exit 1
fi

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

# ���庯�������ļ���
create_directory() {
    local dir_path="$1"
    
    if [ ! -d "$dir_path" ]; then     
        # �����ļ���
        mkdir -p "$dir_path"
        
        if [ $? -ne 0 ]; then
            echo "����ʧ��"
            exit 1
        fi
	fi
}

# ���庯�������ļ�
create_file() {
    local file_path="$1"
    
    if [ -f "$file_path" ]; then
        echo "����iptables����..."
        # ����iptables����
        iptables-save > "$file_path"
    else
        # �����ļ�
        touch "$file_path"
        
        if [ $? -eq 0 ]; then
	    echo "����iptables����..."
            # ����iptables����
            iptables-save > "$file_path"
        else
            echo "����ʧ��"
            exit 1
        fi
    fi
}

# ���ô����ļ��к���
iptables_dir="/etc/iptables"
create_directory "$iptables_dir"

# ���ô����ļ�����
rule_path="/etc/iptables/rules.v4"
create_file "$rule_path"

# ����ulogd����
echo "����ulogd����..."
systemctl restart ulogd2

# �ȴ�һ��ʱ�䣬ȷ�������������
sleep 5

# ���ulogd����״̬
echo "���ulogd����״̬..."
systemctl status ulogd2

# ��ʾ���
echo "�������,HTTP��HTTPS������־��¼��/var/log/ulogd.log�С�"