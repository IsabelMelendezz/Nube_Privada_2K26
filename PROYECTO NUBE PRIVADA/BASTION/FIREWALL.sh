#! /bin/bash

IPTABLES=/sbin/iptables

# -------- Variables de IPs --------
IP_INTERNA=10.10.10.26
IP_DMZ=20.10.10.26
IP_BASTION=192.168.1.13
IP_LAMPAIO=20.10.10.28
#----------------------------------

$IPTABLES -F
$IPTABLES -t nat -F
$IPTABLES -P INPUT ACCEPT
$IPTABLES -P FORWARD ACCEPT
$IPTABLES -P OUTPUT ACCEPT
sysctl -w net.ipv4.ip_forward=1

#---------------INTERNET MAQUINA CLIENTE-------------------
$IPTABLES -t nat -A POSTROUTING -s 10.10.10.0/24 -o enp0s3 -j MASQUERADE
echo "Conectada maquina cliente a internet"

#-------------INTERNET MAQUINA DMZ----------------------
$IPTABLES -t nat -A POSTROUTING -s 20.10.10.0/24 -o enp0s3 -j MASQUERADE

echo "Conectada la DMZ a internet"

#----------redireccionamientos de WEBMIN-----------
echo "Redireccionamiento WEBMIN CLIENTE"
$IPTABLES -A FORWARD -i enp0s3 -p tcp --dport 10001 -j ACCEPT
$IPTABLES -A PREROUTING -t nat -p tcp --dport 10001 -j DNAT --to $IP_INTERNA:10000

echo  "Redireccionamiento WEBMIN DMZ"
$IPTABLES -A FORWARD -i enp0s3 -p tcp  --dport 10002 -j ACCEPT
$IPTABLES -A PREROUTING -t nat -p tcp  --dport 10002 -j DNAT --to $IP_DMZ:10000

#-------------Redireccionamientos SSH--------------------------------
echo "Redireccionamientos mobax cliente y DMZ"
$IPTABLES -A FORWARD -i enp0s3 -p tcp --dport 23 -j ACCEPT
$IPTABLES -A PREROUTING -t nat -p tcp --dport 23 -j DNAT --to $IP_INTERNA:22

$IPTABLES -A FORWARD -i enp0s3 -p tcp --dport 24 -j ACCEPT
$IPTABLES -A PREROUTING -t nat -p tcp --dport 24 -j DNAT --to $IP_DMZ:22

$IPTABLES -A FORWARD -i enp0s3 -p tcp --dport 26 -j ACCEPT 
$IPTABLES -A PREROUTING -t nat -p tcp --dport 26 -j DNAT --to $IP_BASTION:22

#----Redireccionamiento lampaio al 22-------------------
$IPTABLES -A FORWARD  -i enp0s3 -p tcp --dport 22 -j ACCEPT 
$IPTABLES -A PREROUTING -t nat  -p tcp --dport 22 -j DNAT --to $IP_LAMPAIO:22 

#---------------Puertos 80 y 1898---------------------------------
echo "redireccionamiento puerto 1898"
$IPTABLES -A FORWARD -i enp0s3 -p tcp --dport 1898 -j ACCEPT
$IPTABLES -A PREROUTING -t nat -p tcp --dport 1898 -j DNAT --to $IP_LAMPAIO:1898

$IPTABLES -A FORWARD -i enp0s3 -p TCP --dport 80 -j ACCEPT
$IPTABLES -A PREROUTING -t nat -p TCP --dport 80 -j DNAT --to $IP_LAMPAIO:80

#-------Redireccionamientos proxy transparente-------------

# ----------- PUERTO 80 -----------
$IPTABLES -t nat -A PREROUTING -i enp0s8 -p tcp --dport 80 -j REDIRECT --to-port 3129
$IPTABLES -t nat -A PREROUTING -i enp0s9 -p tcp --dport 80 -j REDIRECT --to-port 3129

#----PUERTO 443------
$IPTABLES -t nat -A PREROUTING -i enp0s8 -p tcp --dport 443 -j REDIRECT --to-port 3130
$IPTABLES -t nat -A PREROUTING -i enp0s9 -p tcp --dport 443 -j REDIRECT --to-port 3130


#------------MYSQL PARA CONEXION ODBC---------------------------------
echo "DPT MYSQL Interna 3306"
$IPTABLES -A FORWARD -i enp0s3 -p tcp --dport 3306 -j ACCEPT
$IPTABLES -t nat -A PREROUTING -i enp0s3 -p tcp --dport 3306 -j DNAT --to $IP_INTERNA:3306

echo "DPT MYSQL DMZ 3307"
$IPTABLES -A FORWARD -i enp0s3 -p tcp --dport 3307 -j ACCEPT
$IPTABLES -t nat -A PREROUTING -i enp0s3 -p tcp --dport 3307 -j DNAT --to $IP_DMZ:3306


#-------------------------SQUID FIREFOX-----------------------
$IPTABLES -I FORWARD -p udp --dport 443 -j DROP
$IPTABLES -I INPUT -p udp --dport 443 -j DROP 

$IPTABLES -I OUTPUT -d 151.101.0.0/16 -j REJECT
$IPTABLES -I OUTPUT -d 44.227.89.0/24 -j REJECT
$IPTABLES -I OUTPUT -d 168.232.78.0/24 -j REJECT
$IPTABLES -I OUTPUT -d 54.71.130.143/32 -j REJECT
$IPTABLES -I OUTPUT -d 44.230.115.108/32 -j REJECT
$IPTABLES -I OUTPUT -d 54.148.196.163/32 -j REJECT

#-----------------BLOQUEO SITIOS PROHIBIDOS FORWARD---------------------------
$IPTABLES -I FORWARD -d 151.101.0.0/16 -j REJECT
$IPTABLES -I FORWARD -d 44.227.89.0/24 -j REJECT
$IPTABLES -I FORWARD -d 168.232.78.0/24 -j REJECT
$IPTABLES -I FORWARD -d 54.71.130.143/32 -j REJECT
$IPTABLES -I FORWARD -d 44.230.115.108/32 -j REJECT
$IPTABLES -I FORWARD -d 54.148.196.163/32 -j REJECT

#----------------- CORREO ------------------------
echo "Redireccionamiento CORREOS"
$IPTABLES -A FORWARD -i enp0s3 -p tcp --dport 25 -j ACCEPT
$IPTABLES -t nat -A PREROUTING -i enp0s3 -p tcp --dport 25 -j DNAT --to $IP_DMZ:25
$IPTABLES -A FORWARD -i enp0s3 -p tcp --dport 110 -j ACCEPT
$IPTABLES -t nat -A PREROUTING -i enp0s3 -p tcp --dport 110 -j DNAT --to $IP_DMZ:110
$IPTABLES -A FORWARD -i enp0s3 -p tcp --dport 143 -j ACCEPT
$IPTABLES -t nat -A PREROUTING -i enp0s3 -p tcp --dport 143 -j DNAT --to $IP_DMZ:143


#----------- Reglas de replicación MySQL BIDIRECCIONAL -------------

# Trafico MySQL Interna -> DMZ
$IPTABLES -A FORWARD -i enp0s8 -o enp0s9 -p tcp --dport 3306 -j ACCEPT
$IPTABLES -A FORWARD -i enp0s9 -o enp0s8 -p tcp --dport 3306 -j ACCEPT

# Trafico de respuesta
$IPTABLES -A FORWARD -i enp0s8 -o enp0s9 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A FORWARD -i enp0s9 -o enp0s8 -m state --state ESTABLISHED,RELATED -j ACCEPT

# MASQUERADE entre redes internas
$IPTABLES -t nat -A POSTROUTING -s 10.10.10.0/24 -o enp0s9 -j MASQUERADE
$IPTABLES -t nat -A POSTROUTING -s 20.10.10.0/24 -o enp0s8 -j MASQUERADE

#----------BITACORA FUNCIONANDO-------------------------

echo "Bitacora Funcionando"
$IPTABLES -A INPUT -p icmp -j LOG --log-prefix "Trafico Ping"
$IPTABLES -A INPUT -p tcp --dport 22 -j LOG --log-prefix "Trafico SSH"
$IPTABLES -A FORWARD -p tcp --dport 22 -j LOG --log-prefix "TRAFICO SSH"
$IPTABLES -A FORWARD -p tcp --dport 25 -d $IP_DMZ -j LOG --log-prefix "Trafico SMTP CORREO DPT 25"
$IPTABLES -A FORWARD -p tcp --dport 110 -d $IP_DMZ -j LOG --log-prefix "Trafico POP3 CORREO DPT 110"
$IPTABLES -A FORWARD -p tcp --dport 143 -d $IP_DMZ -j LOG --log-prefix "Trafico IMAP CORREO DPT 143"



iptables-save>/etc/iptables/rules.v4





