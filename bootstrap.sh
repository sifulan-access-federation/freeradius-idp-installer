#!/bin/bash

# Set your eduroam REALM
VAR_REALM="university.edu.my"

# Set your host certificate public key
PUBLIC_KEY_FILE="/etc/letsencrypt/live/eduroam-idp.university.edu.my/cert.pem"

# Set your host certificate private key
PRIV_KEY_FILE="/etc/letsencrypt/live/eduroam-idp.university.edu.my/privkey.pem"


############# DO NOT EDIT BEYOND THIS LINE #############

# Install package dependency

yum install -y gcc gcc-c++ libatomic libtalloc-devel libtool libtool-ltdl-devel net-snmp-devel net-snmp-utils readline-devel libpcap-devel libcurl-devel openldap-devel python-devel mysql-devel sqlite-devel unixODBC-devel freetds-devel samba4-devel json-c-devel

# Download and Install stable version of freeradius 3

INSTALL_PREFIX="/opt"

FR3_VERSION="release_3_0_21"
INSTALL_PATH="${INSTALL_PREFIX}/eduroam-idp-${FR3_VERSION}"
CONFIG_PATH="${INSTALL_PATH}/etc/raddb"

wget "https://github.com/FreeRADIUS/freeradius-server/archive/${FR3_VERSION}.tar.gz" -O ${FR3_VERSION}.tar.gz
tar -zxf ${FR3_VERSION}.tar.gz
cd freeradius-server-${FR3_VERSION}
./configure --prefix=${INSTALL_PATH}
make
make install
ln -s ${INSTALL_PATH}/sbin/rc.radiusd /etc/rc.d/init.d/

# Update Template

cd ..

## eduroam site setup
awk -vVAR_REALM=$VAR_REALM '{gsub("YOUR_REALM",VAR_REALM); print}' eduroam.temp > ${CONFIG_PATH}/sites-available/eduroam
rm -f ${CONFIG_PATH}/sites-enabled/default
ln -s ${CONFIG_PATH}/sites-available/eduroam ${CONFIG_PATH}/sites-enabled/default

## eap setup
wget https://sifulan.my/download/tls-ca-bundle.pem -O ${CONFIG_PATH}/certs/tls-ca-bundle.pem
awk -vPRIV_KEY_FILE=$PRIV_KEY_FILE -vPUBLIC_KEY_FILE=$PUBLIC_KEY_FILE '{gsub("PRIV_KEY_FILE", PRIV_KEY_FILE); gsub("PUBLIC_KEY_FILE", PUBLIC_KEY_FILE);print}' eap.temp > ${CONFIG_PATH}/mods-available/eap-eduroam
rm -f ${CONFIG_PATH}/mods-enabled/eap
ln -s ${CONFIG_PATH}/mods-available/eap-eduroam ${CONFIG_PATH}/mods-enabled/eap

## linelog setup
cp linelog ${CONFIG_PATH}/mods-available/linelog-eduroam
rm -f ${CONFIG_PATH}/mods-enabled/linelog
ln -s ${CONFIG_PATH}/mods-available/linelog-eduroam ${CONFIG_PATH}/mods-enabled/linelog

## rsyslog setup
echo "local0.debug /var/log/radius_auth.log" > /etc/rsyslog.d/radiusd.conf
service rsyslog restart

## client setup
cp -f clients.conf ${CONFIG_PATH}/clients.conf

## inner-tunnel setup
cp inner-tunnel ${CONFIG_PATH}/sites-available/eduroam-inner-tunnel
rm -f ${CONFIG_PATH}/sites-enabled/inner-tunnel
ln -s ${CONFIG_PATH}/sites-available/eduroam-inner-tunnel ${CONFIG_PATH}/sites-enabled/inner-tunnel

## inner-eap setup
cp inner-eap ${CONFIG_PATH}/mods-available/inner-eap-eduroam
ln -s ${CONFIG_PATH}/mods-available/inner-eap-eduroam ${CONFIG_PATH}/mods-enabled/inner-eap 

## radsec setup
awk -vPRIV_KEY_FILE=$PRIV_KEY_FILE -vPUBLIC_KEY_FILE=$PUBLIC_KEY_FILE '{gsub("PRIV_KEY_FILE", PRIV_KEY_FILE); gsub("PUBLIC_KEY_FILE", PUBLIC_KEY_FILE);print}' radsec.temp > ${CONFIG_PATH}/sites-available/radsec-eduroam
ln -s ${CONFIG_PATH}/sites-available/radsec-eduroam ${CONFIG_PATH}/sites-enabled/radsec

## fticks setup
cp f_ticks.temp ${CONFIG_PATH}/mods-available/f_ticks
ln -s ${CONFIG_PATH}/mods-available/f_ticks ${CONFIG_PATH}/mods-enabled/f_ticks


echo "done!!!"




