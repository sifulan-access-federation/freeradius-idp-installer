# Freeradius IdP Installer

## Overview
The Freeradius IdP Installer is designed by SIFULAN Malaysian Access Federation to automate the install of version 3 for the Freerdius eduroam IdP on a dedicated CentOS 7 server. This installer was based on Freeradius' 3 basic eduroam configuration [https://wiki.freeradius.org/guide/eduroam](https://wiki.freeradius.org/guide/eduroam) with some modifications to work with eduroam Malaysian NRO's configuration.

This installer is provided as it is, WITHOUT any support nor warranty.

## License
Apache License Version 2.0, January 2004

## Installation Guide

Note: In this installation guide,  hostname `eduroam-idp.university.edu.my` and realm `university.edu.my` are used as an example. You should replace it with your actual hostname and realm.

### Resource Requirement

A dedicated CentOS 7 (virtual or physical), with the following minimum specifications:
- 2 CPU cores
- 4GB RAM
- 10GB partition for OS

#### Additional Requirement
- The server MUST NOT be used for any other purpose in the future.
- You MUST be able to execute commands as `root` on the system without limitation
- The server MUST be accessible from the public internet.
- The static IP MUST have a publicly resolvable DNS entry (e.g `eduroam-idp.university.edu.my`)
- The following ports and inbound/outbound connections from/to public network (i.e. Internet) MUST be allowed:

Port | Protocol | Purpose | Direction
- | - | - | -
80 | tcp | Let's encrypt domain validation | inbound
2083 | tcp | radsec connection to NROs | inbound & outbound


#### Obtain Host Certificate from Let's Encrypt

##### Install certbot-auto

```bash
[root@eduroam-idp ~]# wget https://dl.eff.org/certbot-auto
[root@eduroam-idp ~]# mv certbot-auto /usr/local/bin/certbot-auto
[root@eduroam-idp ~]# chown root /usr/local/bin/certbot-auto
[root@eduroam-idp ~]# chmod 0755 /usr/local/bin/certbot-auto
[root@eduroam-idp ~]# certbot-auto --install-only
```

##### Get a host certificate from Let's Encrypt

```bash
[root@eduroam-idp ~]# certbot-auto certonly --standalone -d eduroam-idp.university.edu.my
```

### Setup and Run freeradius-idp-installer tool

##### Download and Extract freeradius-idp-installer tool

```bash
[root@eduroam-idp ~]# wget https://github.com/sifulan-access-federation/freeradius-idp-installer/archive/master.zip
[root@eduroam-idp ~]# unzip master.unzip
[root@eduroam-idp ~]# cd freeradius-idp-installer-master
[root@eduroam-idp freeradius-idp-installer-master]#
```
##### Edit the Bootstrap script

```bash
[root@eduroam-idp freeradius-idp-installer-master]# vi bootstrap.sh
```

Edit the following options according to your organization/settings:

```
# Set your eduroam REALM
VAR_REALM="university.edu.my"

# Set your host certificate public key
PUBLIC_KEY_FILE="/etc/letsencrypt/live/eduroam-idp.university.edu.my/cert.pem"

# Set your host certificate private key
PRIV_KEY_FILE="/etc/letsencrypt/live/eduroam-idp.university.edu.my/privkey.pem"
```
##### Run the Bootstrap script

```bash
[root@eduroam-idp freeradius-idp-installer-master]# ./bootstrap.sh
```
##### Test the freeradius installation

```bash
[root@eduroam-idp freeradius-idp-installer-master]# cd /opt/eduroam-idp-release_3_0_21/etc/raddb/
[root@eduroam-idp raddb]# ../../sbin/radiusd -fxx -l stdout
```
If the command gives the output like below it means the bootstrap script ran correctly. Press `ctrl + c` to stop the process.
```
...
...
Listening on auth+acct proto tcp address * port 2083 (TLS) bound to server eduroam
Listening on auth address * port 1812 bound to server eduroam
Listening on auth address * port 18120 bound to server eduroam-inner
Listening on proxy address * port 56685
Ready to process requests
```
Run the service:
```bash
[root@eduroam-idp raddb]# service rc.radiusd start
```

### Linking with Wi-Fi Access Point/Controller
Edit `clients.conf` file:
```bash
[root@eduroam-idp raddb]# vi clients.conf
```
Add your Wi-Fi Access Point/Controller information by following the template below:
```
client wireless_access_points_mgmt {
  ipaddr = <ip-address>/<cidr-mask>
  secret = <secret/password>
}
```
Restart `radiusd` daemon:
```bash
[root@eduroam-idp raddb]# service rc.radiusd restart
```

### Linking with Directory Service
#### LDAP
Create `ldap` module file:
```bash
[root@eduroam-idp raddb]# vi mods-available/ldap
```
```
ldap  {

        server = ldap.university.edu.my <- change with your ldap server
        identity = "cn=admin,dc=university,dc=edu,dc=my" <- change with your ldap admin user bind
        password = "PASSWORD" <- change with your ldap admin user bind password
        filter = "(uid=%{Stripped-User-Name})"
        ldap_connections_number = 5
        timeout = 4
        timelimit = 3
        net_timeout = 1
        password_header = "{SHA}" <- change with your password hashing algorithm
        user {
            base_dn = "ou=People,dc=idp,dc=university,dc=edu,dc=my" <- change with your base dn
            filter = "(uid=%{Stripped-User-Name})"
        }

        update {
            control:Password-With-Header    += 'userPassword'
            control:NT-Password             := 'sambaNTPassword'
            control:LM-Password             := 'sambaLMPassword'
        }

}
```
Enable the `ldap` module:
```bash
[root@eduroam-idp raddb]# ln -s mods-available/ldap mods-enabled/
```
Edit the `inner-tunnel` configuration file:
```bash
[root@eduroam-idp raddb]# vi site-enabled/inner-tunnel
```
Comment `files` option and add `ldap` option:
```
...
...
# EAP-TTLS-PAP and PEAPv0 are equally secure/insecure depending on how the
# supplicant is configured. PEAPv0 has a slight edge in that you need to
# crack MSCHAPv2 to get the user's password (but this is not hard).
#files
ldap
pap
mschap
```
Restart `radiusd` daemon:
```bash
[root@eduroam-idp raddb]# service rc.radiusd restart
```
