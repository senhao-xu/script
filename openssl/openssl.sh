#! /bin/bash
#颜色
red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'
_red() { echo -e ${red}$*${none}; }
_green() { echo -e ${green}$*${none}; }
_yellow() { echo -e ${yellow}$*${none}; }
_magenta() { echo -e ${magenta}$*${none}; }
_cyan() { echo -e ${cyan}$*${none}; }
#DOMAIN=harbormaster.com
#DOMAIN_EXT=
#IP=0.0.0.0
#DATE=3650

read -p "$(echo -e "请输入域名: $none")" DOMAIN
read -p "$(echo -e "请输入IP: $none")" IP
read -p "$(echo -e "请输入日期: $none")" DATE

## generate CA : cakey.pem && cacerts.pem
if [[ ! -e "cacerts.pem" || ! -e "cakey.pem" ]]
then
  openssl genrsa -out cakey.pem 2048
  openssl req -x509 -new -nodes -key cakey.pem -subj "/CN=zerchin" -days ${DATE} -out cacerts.pem 
fi


## generate server tls
mkdir ${DOMAIN}
openssl genrsa -out ${DOMAIN}/tls.key 2048

cat > ${DOMAIN}/csr.conf << EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn
[ dn ]
C = CN
ST = GD
L = SZ
O = zerchin
OU = zerchin
CN = ${DOMAIN}
[ req_ext ]
subjectAltName = @alt_names
[ alt_names ]
EOF
if [[ -n ${DOMAIN_EXT} ]]
then
    IFS=","
    DNS=(${DOMAIN})
    DNS+=(${DOMAIN_EXT})
    for i in ${!DNS[@]} 
    do
        echo DNS.${i} "=" ${DNS[$i]} >> ${DOMAIN}/csr.conf
    done
    echo DNS.
fi
if [[ -n ${IP} ]]
then
    IFS=","
    ip=(${IP})
    for i in ${!ip[@]} 
    do
        echo IP.${i} "=" ${ip[$i]} >> ${DOMAIN}/csr.conf
    done
    echo DNS.
fi
cat >> ${DOMAIN}/csr.conf << EOF
[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOF


# 
openssl req -new -key ${DOMAIN}/tls.key -out ${DOMAIN}/tls.csr -config ${DOMAIN}/csr.conf

#
openssl x509 -req -in ${DOMAIN}/tls.csr -CA cacerts.pem  -CAkey cakey.pem \
  -CAcreateserial -out ${DOMAIN}/tls.crt -days ${DATE} \
  -extensions v3_ext -extfile ${DOMAIN}/csr.conf
