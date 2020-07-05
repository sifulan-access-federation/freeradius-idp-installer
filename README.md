# Freeradius IdP Installer

## Overview
The Freeradius IdP Installer is designed by SIFULAN Malaysian Access Federation to automate the install of version 3 for the Freerdius eduroam IdP on a dedicated CentOS 7 server. This installer was based on Freeradius' 3 basic eduroam configuration [https://wiki.freeradius.org/guide/eduroam](https://wiki.freeradius.org/guide/eduroam) with some modifications to work with eduroam Malaysian NRO's configuration.

This installer is provided as it is, WITHOUT any support nor warranty.

## License
Apache License Version 2.0, January 2004

## Installation Guide

### Resource Requirement

A dedicated CentOS 7 (virtual or physical), with the following minimum specifications:
- 2 CPU cores
- 4GB RAM
- 10GB partition for OS

#### Additional Requirement
- The server MUST NOT be used for any other purpose in the future.
- You MUST be able to execute commands as `root` on the system without limitation
- The server MUST be accessible from the public internet.
- The static IP MUST have a publicly resolvable DNS entry. Typically of the form `eduroam-idp.university.edu.my`
- The following ports and inbound/outbound connections from/to public network (i.e. Internet) MUST be allowed:

| Port | Protocol | Purpose | Direction
- | - | - | -
80 | tcp | Let's encrypt domain validation | inbound
2083 | tcp | radsec connection to NROs | inbound & outbound


### Obtain Host Certificate from Let's Encrypt

Install certbot-auto

```bash
[root@eduroam-idp ~]# wget https://dl.eff.org/certbot-auto
[root@eduroam-idp ~]# mv certbot-auto /usr/local/bin/certbot-auto
[root@eduroam-idp ~]# chown root /usr/local/bin/certbot-auto
[root@eduroam-idp ~]# chmod 0755 /usr/local/bin/certbot-auto
[root@eduroam-idp ~]# /usr/local/bin/certbot-auto --install-only
```
