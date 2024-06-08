#!/bin/bash
  
#write by zhumaohai(admin#centos.bz)
#author blog: www.centos.bz
  
  
#��ʾ�˵�(��ѡ)
display_menu(){
local soft=$1
local prompt="which ${soft} you'd select: "
eval local arr=(\${${soft}_arr[@]})
while true
do
    echo -e "#################### ${soft} setting ####################\n\n"
    for ((i=1;i<=${#arr[@]};i++ )); do echo -e "$i) ${arr[$i-1]}"; done
    echo
    read -p "${prompt}" $soft
    eval local select=\$$soft
    if [ "$select" == "" ] || [ "${arr[$soft-1]}" == ""  ];then
        prompt="input errors,please input a number: "
    else
        eval $soft=${arr[$soft-1]}
        eval echo "your selection: \$$soft"            
        break
    fi
done
}
  
#�Ѵ���bit��λת��Ϊ����ɶ���λ
bit_to_human_readable(){
    #input bit value
    local trafficValue=$1
  
    if [[ ${trafficValue%.*} -gt 922 ]];then
        #conv to Kb
        trafficValue=`awk -v value=$trafficValue 'BEGIN{printf "%0.1f",value/1024}'`
        if [[ ${trafficValue%.*} -gt 922 ]];then
            #conv to Mb
            trafficValue=`awk -v value=$trafficValue 'BEGIN{printf "%0.1f",value/1024}'`
            echo "${trafficValue}Mb"
        else
            echo "${trafficValue}Kb"
        fi
    else
        echo "${trafficValue}b"
    fi
}
  
#�жϰ�������
check_package_manager(){
    local manager=$1
    local systemPackage=''
    if cat /etc/issue | grep -q -E -i "ubuntu|debian";then
        systemPackage='apt'
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat";then
        systemPackage='yum'
    elif cat /proc/version | grep -q -E -i "ubuntu|debian";then
        systemPackage='apt'
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat";then
        systemPackage='yum'
    else
        echo "unkonw"
    fi
  
    if [ "$manager" == "$systemPackage" ];then
        return 0
    else
        return 1
    fi  
}
  
  
#ʵʱ����
realTimeTraffic(){
    local eth=""
    local nic_arr=(`ifconfig | grep -E -o "^[a-z0-9]+" | grep -v "lo" | uniq`)
    local nicLen=${#nic_arr[@]}
    if [[ $nicLen -eq 0 ]]; then
        echo "sorry,I can not detect any network device,please report this issue to author."
        exit 1
    elif [[ $nicLen -eq 1 ]]; then
        eth=$nic_arr
    else
        display_menu nic
        eth=$nic
    fi  
  
    local clear=true
    local eth_in_peak=0
    local eth_out_peak=0
    local eth_in=0
    local eth_out=0
  
    while true;do
        #�ƶ���굽0:0λ��
        printf "\033[0;0H"
        #��������ӡNow Peak
        [[ $clear == true ]] && printf "\033[2J" && echo "$eth--------Now--------Peak-----------"
        traffic_be=(`awk -v eth=$eth -F'[: ]+' '{if ($0 ~eth){print $3,$11}}' /proc/net/dev`)
        sleep 2
        traffic_af=(`awk -v eth=$eth -F'[: ]+' '{if ($0 ~eth){print $3,$11}}' /proc/net/dev`)
        #��������
        eth_in=$(( (${traffic_af[0]}-${traffic_be[0]})*8/2 ))
        eth_out=$(( (${traffic_af[1]}-${traffic_be[1]})*8/2 ))
        #����������ֵ
        [[ $eth_in -gt $eth_in_peak ]] && eth_in_peak=$eth_in
        [[ $eth_out -gt $eth_out_peak ]] && eth_out_peak=$eth_out
        #�ƶ���굽2:1
        printf "\033[2;1H"
        #�����ǰ��
        printf "\033[K"  
        printf "%-20s %-20s\n" "Receive:  $(bit_to_human_readable $eth_in)" "$(bit_to_human_readable $eth_in_peak)"
        #�����ǰ��
        printf "\033[K"
        printf "%-20s %-20s\n" "Transmit: $(bit_to_human_readable $eth_out)" "$(bit_to_human_readable $eth_out_peak)"
        [[ $clear == true ]] && clear=false
    done
}
  
#���������Ӹ���
trafficAndConnectionOverview(){
    if ! which tcpdump > /dev/null;then
        echo "tcpdump not found,going to install it."
        if check_package_manager apt;then
            apt-get -y install tcpdump
        elif check_package_manager yum;then
            yum -y install tcpdump
        fi
    fi
  
    local reg=""
    local eth=""
    local nic_arr=(`ifconfig | grep -E -o "^[a-z0-9]+" | grep -v "lo" | uniq`)
    local nicLen=${#nic_arr[@]}
    if [[ $nicLen -eq 0 ]]; then
        echo "sorry,I can not detect any network device,please report this issue to author."
        exit 1
    elif [[ $nicLen -eq 1 ]]; then
        eth=$nic_arr
    else
        display_menu nic
        eth=$nic
    fi
  
    echo "please wait for 10s to generate network data..."
    echo
    #��ǰ����ֵ
    local traffic_be=(`awk -v eth=$eth -F'[: ]+' '{if ($0 ~eth){print $3,$11}}' /proc/net/dev`)
    #tcpdump��������
    tcpdump -v -i $eth -tnn > /tmp/tcpdump_temp 2>&1 &
    sleep 10
    clear
    kill `ps aux | grep tcpdump | grep -v grep | awk '{print $2}'`
  
    #10s������ֵ
    local traffic_af=(`awk -v eth=$eth -F'[: ]+' '{if ($0 ~eth){print $3,$11}}' /proc/net/dev`)
    #��ӡ10sƽ������
    local eth_in=$(( (${traffic_af[0]}-${traffic_be[0]})*8/10 ))
    local eth_out=$(( (${traffic_af[1]}-${traffic_be[1]})*8/10 ))
    echo -e "\033[32mnetwork device $eth average traffic in 10s: \033[0m"
    echo "$eth Receive: $(bit_to_human_readable $eth_in)/s"
    echo "$eth Transmit: $(bit_to_human_readable $eth_out)/s"
    echo
  
    local regTcpdump=$(ifconfig | grep -A 1 $eth | awk -F'[: ]+' '$0~/inet addr:/{printf $4"|"}' | sed -e 's/|$//' -e 's/^/(/' -e 's/$/)\\\\\.[0-9]+:/')
  
    #�¾ɰ汾tcpdump�����ʽ��һ��,�ֱ���
    if awk '/^IP/{print;exit}' /tmp/tcpdump_temp | grep -q ")$";then
        #����tcpdump�ļ�
        awk '/^IP/{print;getline;print}' /tmp/tcpdump_temp > /tmp/tcpdump_temp2
    else
        #����tcpdump�ļ�
        awk '/^IP/{print}' /tmp/tcpdump_temp > /tmp/tcpdump_temp2
        sed -i -r 's#(.*: [0-9]+\))(.*)#\1\n    \2#' /tmp/tcpdump_temp2
    fi
     
    awk '{len=$NF;sub(/\)/,"",len);getline;print $0,len}' /tmp/tcpdump_temp2 > /tmp/tcpdump
  
    #ͳ��ÿ���˿���10s�ڵ�ƽ������
    echo -e "\033[32maverage traffic in 10s base on server port: \033[0m"
    awk -F'[ .:]+' -v regTcpdump=$regTcpdump '{if ($0 ~ regTcpdump){line="clients > "$8"."$9"."$10"."$11":"$12}else{line=$2"."$3"."$4"."$5":"$6" > clients"};sum[line]+=$NF*8/10}END{for (line in sum){printf "%s %d\n",line,sum[line]}}' /tmp/tcpdump | \
    sort -k 4 -nr | head -n 10 | while read a b c d;do
        echo "$a $b $c $(bit_to_human_readable $d)/s"
    done
    echo -ne "\033[11A"
    echo -ne "\033[50C"
    echo -e "\033[32maverage traffic in 10s base on client port: \033[0m"
    awk -F'[ .:]+' -v regTcpdump=$regTcpdump '{if ($0 ~ regTcpdump){line=$2"."$3"."$4"."$5":"$6" > server"}else{line="server > "$8"."$9"."$10"."$11":"$12};sum[line]+=$NF*8/10}END{for (line in sum){printf "%s %d\n",line,sum[line]}}' /tmp/tcpdump | \
    sort -k 4 -nr | head -n 10 | while read a b c d;do
            echo -ne "\033[50C"
            echo "$a $b $c $(bit_to_human_readable $d)/s"
    done  
         
    echo
  
    #ͳ����10s��ռ�ô�������ǰ10��ip
    echo -e "\033[32mtop 10 ip average traffic in 10s base on server: \033[0m"
    awk -F'[ .:]+' -v regTcpdump=$regTcpdump '{if ($0 ~ regTcpdump){line=$2"."$3"."$4"."$5" > "$8"."$9"."$10"."$11":"$12}else{line=$2"."$3"."$4"."$5":"$6" > "$8"."$9"."$10"."$11};sum[line]+=$NF*8/10}END{for (line in sum){printf "%s %d\n",line,sum[line]}}' /tmp/tcpdump | \
    sort -k 4 -nr | head -n 10 | while read a b c d;do
        echo "$a $b $c $(bit_to_human_readable $d)/s"
    done
    echo -ne "\033[11A"
    echo -ne "\033[50C"
    echo -e "\033[32mtop 10 ip average traffic in 10s base on client: \033[0m"
    awk -F'[ .:]+' -v regTcpdump=$regTcpdump '{if ($0 ~ regTcpdump){line=$2"."$3"."$4"."$5":"$6" > "$8"."$9"."$10"."$11}else{line=$2"."$3"."$4"."$5" > "$8"."$9"."$10"."$11":"$12};sum[line]+=$NF*8/10}END{for (line in sum){printf "%s %d\n",line,sum[line]}}' /tmp/tcpdump | \
    sort -k 4 -nr | head -n 10 | while read a b c d;do
        echo -ne "\033[50C"
        echo "$a $b $c $(bit_to_human_readable $d)/s"
    done
  
    echo
    #ͳ������״̬
    local regSS=$(ifconfig | grep -A 1 $eth | awk -F'[: ]+' '$0~/inet addr:/{printf $4"|"}' | sed -e 's/|$//')
    ss -an | grep -v -E "LISTEN|UNCONN" | grep -E "$regSS" > /tmp/ss
    echo -e "\033[32mconnection state count: \033[0m"
    awk 'NR>1{sum[$(NF-4)]+=1}END{for (state in sum){print state,sum[state]}}' /tmp/ss | sort -k 2 -nr
    echo
    #ͳ�Ƹ��˿�����״̬
    echo -e "\033[32mconnection state count by port base on server: \033[0m"
    awk 'NR>1{sum[$(NF-4),$(NF-1)]+=1}END{for (key in sum){split(key,subkey,SUBSEP);print subkey[1],subkey[2],sum[subkey[1],subkey[2]]}}' /tmp/ss | sort -k 3 -nr | head -n 10  
    echo -ne "\033[11A"
    echo -ne "\033[50C"
    echo -e "\033[32mconnection state count by port base on client: \033[0m"
    awk 'NR>1{sum[$(NF-4),$(NF)]+=1}END{for (key in sum){split(key,subkey,SUBSEP);print subkey[1],subkey[2],sum[subkey[1],subkey[2]]}}' /tmp/ss | sort -k 3 -nr | head -n 10 | awk '{print "\033[50C"$0}'  
    echo  
    #ͳ�ƶ˿�Ϊ80��״̬ΪESTAB����������ǰ10��IP
    echo -e "\033[32mtop 10 ip ESTAB state count at port 80: \033[0m"
    cat /tmp/ss | grep ESTAB | awk -F'[: ]+' '{sum[$(NF-2)]+=1}END{for (ip in sum){print ip,sum[ip]}}' | sort -k 2 -nr | head -n 10
    echo
    #ͳ�ƶ˿�Ϊ80��״̬ΪSYN-RECV����������ǰ10��IP
    echo -e "\033[32mtop 10 ip SYN-RECV state count at port 80: \033[0m"
    cat /tmp/ss | grep -E "$regSS" | grep SYN-RECV | awk -F'[: ]+' '{sum[$(NF-2)]+=1}END{for (ip in sum){print ip,sum[ip]}}' | sort -k 2 -nr | head -n 10
}
  
main(){
    while true; do
        echo -e "1) real time traffic.\n2) traffic and connection overview.\n"
        read -p "please input your select(ie 1): " select
        case  $select in
            1) realTimeTraffic;break;;
            2) trafficAndConnectionOverview;break;;
            *) echo "input error,please input a number.";;
        esac
    done  
}
  
main