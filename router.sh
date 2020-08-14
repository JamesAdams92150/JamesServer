
#!/bin/sh
IPT=/sbin/iptables
WANIF=enp6s0
LANIF=enp1s0
LANIF2=enp3s0
LANIF3=enp4s0

firewall_start() { #Exécuter lors du routeur.sh start
	
		#==================== INPUT ===================
        #Ces règles s'appliquent aux paquets entrants

        #Tout ce qui sort peut rentrer à nouveau 
        $IPT -A INPUT -i $WANIF -m state --state ESTABLISHED,RELATED -j ACCEPT 
		
		#On ouvre le port 22 depuis le WAN sur notre rotueur pour permettre son management à distance. 
		#Cette étape n'est pas obligatoire et dépend de votre configuration
        #$IPT -A INPUT -i $WANIF -p tcp --dport 22 -j ACCEPT 
	$IPT -A INPUT -i $WANIF -p tcp --dport 25565 -j ACCEPT
	$IPT -A INPUT -i $LANIF2 -p tcp --dport 25565 -j ACCEPT
        #$IPT -A INPUT -i $WANIF -p tcp --dport 80 -j ACCEPT
        #$IPT -A INPUT -i $LANIF -p tcp --dport 80 -j ACCEPT
        #$IPT -A INPUT -i $WANIF -p tcp --dport 2022 -j ACCEPT
        #$IPT -A INPUT -i $LANIF -p tcp --dport 2022 -j ACCEPT

	
			
		#On autorise le PING sur l'interface WAN (facultatif)
        $IPT -A INPUT -i $WANIF -p icmp -j ACCEPT
		
		#On laisse passer tout ce qui rentre dans l'interface lan afin de permettre à nos utilisateurs d'utiliser le DHCP et le DNS
        $IPT -A INPUT -i $LANIF -j ACCEPT
        $IPT -A INPUT -i $LANIF2 -j ACCEPT
        $IPT -A INPUT -i $LANIF3 -j ACCEPT


		
		#Tout ce qui ne MATCH pas avec les règles précédente > ON jette !
        $IPT -P INPUT DROP
		

		#==================== NAT ===================
        #Ces règles effectuent la réécriture d'adresses du NAT
		
		#Tout ce qui a fini de traverser le routeur (postrouting) et qui sort par le WAN sera NATté
        $IPT -A POSTROUTING -t nat -o $WANIF -j MASQUERADE


		#==================== FORWARD ===================
        #Ces règles s'appliquent au paquets traversant le routeur
		
		#Tout ce qui vient du WAN et sort par le LAN et qui correspond à une réponse est autoriser à passer.
        $IPT -A FORWARD -i $WANIF -m state --state ESTABLISHED,RELATED -j ACCEPT
		
		#Tout ce qui part du LAN est autoriser à traverser le routeur.
        $IPT -A FORWARD -i $LANIF -j ACCEPT
        $IPT -A FORWARD -i $LANIF2 -j ACCEPT
        $IPT -A FORWARD -i $LANIF3 -j ACCEPT
	

	
	#$IPT -A PREROUTING -t nat -i $WANIF -p tcp --dport 2202 -j DNAT --to 192.168.0.160:2202
	#$ipt -A FORWARD -p tcp -d 192.168.0.160 --dport 2202 -j ACCEPT
	#$IPT -A FORWARD -i $WANIF -p tcp --dport 80 -d 192.168.0.152 -j ACCEPT
	#$IPT -A PREROUTING -t nat -j DNAT -i $WANIF -p tcp --dport 80 --to-destination 192.168.0.152:80
        $IPT -A FORWARD -i $WANIF -p tcp --dport 25565 -d 192.168.2.1 -j ACCEPT
        $IPT -A PREROUTING -t nat -j DNAT -i $WANIF -p tcp --dport 25565 --to-destination 192.168.2.1:25565
        #$IPT -A FORWARD -i $WANIF -p tcp --dport 2022 -d 192.168.0.153 -j ACCEPT
        #$IPT -A PREROUTING -t nat -j DNAT -i $WANIF -p tcp --dport 2022 --to-destination 192.168.0.153:2022


		#Tout ce qui ne MATCH pas avec les règles précédente > ON jette !
        $IPT -P FORWARD DROP

		


                #==================== PORTS ===================
	#ouverture et fermeture des ports

		#LANIF
	#$IPT -I INPUT -p tcp 192.168.2.1 --dport 25565 -j ACCEPT
	#$IPT -I INPUT -p tcp -s 0.0.0.0/0 --dport 25565 -j DROP
	#$IPT -A FORWARD -i $WANIF -p tcp --dport 25565 -d 192.168.2.1 -j ACCEPT
	#$IPT -A PREROUTING -t nat -j DNAT -i $WANIF -p tcp --dport 25565 --to-destination 192.168.2.1:25565
	#$IPT -A POSTROUTING -t nat -p tcp -d 192.168.2.1 --dport 25565 -j MASQUERADE
	#$IPT -A FORWARD -p tcp -d 192.168.2.1 --dport 25565 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	#$IPT -A INPUT -p tcp -m tcp --dport 25565 -j ACCEPT
	#$IPT -A PREROUTING -t nat -i $WANIF -p tcp -m tcp --dport 25565 -j DNAT --to 192.168.1.50:25565
	#$IPT -A FORWARD -i $WANIF -o $LANIF2 -p tcp -m tcp -d 192.168.1.50 --dport 25565 -j ACCEPT
	#$IPT -A FORWARD -i $WANIF -p tcp --dport 25565 -d 192.168.2.1 -j ACCEPT
	#$IPT -A FORWARD -i $LANIF2 -p tcp --dport 25565 -d 192.168.2.1 -j ACCEPT
	#$IPT -A PREROUTING -T nat -j DNAT -i $WANIF -p tcp --dport 25565 --to-destination 192.168.2.1:25565
}

firewall_stop() { #exécuté lors du routeur.sh stop
		
		#Clear des différentes tables d'iptables et remise à zéro de la configuration.
        $IPT -F
        $IPT -t nat -F
        $IPT -P INPUT ACCEPT
        $IPT -P FORWARD ACCEPT
}

firewall_restart() { #exécuté lors du routeur.sh restart
        firewall_stop
        sleep 2
        firewall_start
}

case $1 in 'start' )
firewall_start
;;
'stop' )
firewall_stop
;;
'restart' )
firewall_restart
;;
*)
echo "usage: -bash {start|stop|restart}"
;;
esac
