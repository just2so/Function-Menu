#!/bin/bash

#���ܣ������������״̬�ű�

TCP_Total=$(ss -s | awk '$1=="TCP"{print $2}') #����TCP���Ӹ���
UDP_Total=$(ss -s | awk '$1=="UDP"{print $2}') #����UDP���Ӹ���
Unix_sockets_Total=$(ss -ax | awk 'BEGIN{count=0} {count++} END{print count}') #����UNIX sockets���Ӹ���
TCP_Listen_Total=$(ss -antlpH | awk 'BEGIN{count=0} {count++} END{print count}') #���д���Listen����״̬��TCP�˿ڸ���
TCP_Estab_Total=$(ss -antph | awk 'BEGIN{count=0} /^ESTAB/{count++} END{print count}') #���д���ESTABLISHED״̬TCP���Ӹ���
TCP_SYN_RECV_Total=$(ss -antpH | awk 'BEGIN{count=0} /^SYN-RECV/{count++} END{print count}') #���д���SYN_RECV״̬��TCP���Ӹ���
TCP_TIME_WAIT_Total=$(ss -antpH | awk 'BEGIN{count=0} /^TIME-WAIT/{count++} END{print count}') #���д���TIME-WAIT״̬��TCP���Ӹ���
TCP_TIME_WAIT1_Total=$(ss -antpH | awk 'BEGIN{count=0} /^TIME-WAIT1/{count++} END{print count}') #���д���TIME-WAIT1״̬��TCP���Ӹ���
TCP_TIME_WAIT2_Total=$(ss -antpH | awk 'BEGIN{count=0} /^TIME-WAIT2/{count++} END{print count}') #���д���TIME-WAIT2״̬��TCP���Ӹ���
TCP_Remote_Count=$(ss -antH | awk '$1!~/LISTEN/{IP[$5]++} END{ for(i in IP) {print IP[i],i} }' | sort -nr) #����Զ������TCP���Ӵ���
TCP_Port_Count=$(ss -antH | sed -r 's/ +/ /g' | awk -F"[ :]" '$1!~/LISTEN/{port[$5]++} END{for(i in port) {print port[i],i}}' | sort -nr) #ÿ���˿ڱ����ʴ���

#���������ɫ

SUCCESS="echo -en \\033[1;32m"  #��ɫ
NORMAL="echo -en \\033[0;39m" #��ɫ

#��ʾTCP��������
tcp_total(){

	echo -n "TCP��������: "
	$SUCCESS
	echo "$TCP_Total"
	$NORMAL
}

#��ʾ����LISTEN״̬��TCP�˿ڸ���

tcp_listen(){
	echo -n "����LISTEN״̬��TCP�˿ڸ���"
	$SUCCESS
	echo "$TCP_Listen_Total"
	$NORMAL
}

#��ʾ����ESTABLISHED״̬��TCP���Ӹ���
tcp_estab(){
	echo -n "����ESTAB״̬��TCP���Ӹ���:"
	$SUCCESS
	echo "TCP_Estab_Total"
	$NORMAL
}

#��ʾ����SYN-RECV״̬��TCP���Ӹ���

tcp_syn_recv(){
	echo -n "����SYN-RECV״̬��TCP���Ӹ���:"
	$SUCCESS
	echo "TCP_SYN_RECV_Total"
	$NORMAL
}

#��ʾ����TIME-WAIT״̬��TCP���Ӹ���

tcp_time_wait(){
	echo -n "����TIME-WAIT״̬��TCP���Ӹ���:"
	$SUCCESS
	echo "$TCP_TIME_WAIT_Total"
	$NORMAL
}

#��ʾ����TIME-WAIT1״̬��TCP���Ӹ���
tcp_time_wait1(){
	echo -n "����TIME-WAIT1״̬��TCP���Ӹ���:"
	$SUCCESS
	echo "$TCP_TIME_WAIT1_Total"
	$NoRMAL
}

#��ʾ����TIME-WAIT2״̬��TCP���Ӹ���
tcp_time_wait2(){
	echo -n "����TIME-WAIT2״̬��TCP���Ӹ���:"
	$SUCCESS
	echo "$TCP_TIME_WAIT2_Total"
	$NORMAL
}

#��ʾUDP��������

udp_total(){
	echo -n "UDP��������:"
	$SUCCESS
	echo "$UDP_Total"
	$NORMAL
}

#��ʾUNIX sockets��������

unix_total(){
	echo -n "Unix sockets ��������:"
	$SUCCESS
	echo "$Unix_sockets_Total"
	$NORMAL
}

#��ʾÿ��Զ�������ķ��ʴ���
remote_count(){
	echo -n "ÿ��Զ�������뱾���Ĳ���������:"
	$SUCCESS
	echo "$TCP_Remote_Count"
	$NORMAL
}

#��ʾÿ���˿ڵĲ���������

port_count(){
	echo -n "ÿ���˿ڵĲ���������:"
	$SUCCESS
	echo "$TCP_Port_Count"
	$NORMAL
}

print_info(){
	echo -e "================================================================="
	$1
}

print_info tcp_total
print_info tcp_listen
print_info tcp_estab
print_info tcp_syn_recv
print_info tcp_time_wait
print_info tcp_time_wait1
print_info tcp_time_wait2
print_info udp_total
print_info unix_total
print_info remote_count
print_info port_count

echo -e "================================================================="

