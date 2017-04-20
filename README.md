Virtualhost Manage Script
===========

Bash Script to allow create or delete apache2 virtual hosts on Ubuntu on a quick way. Allow force to HTTPS with self-signed cert.
Based on https://github.com/RoverWire/virtualhost

## Installation ##

1. Download the script
2. Apply permission to execute:

```
$ chmod +x /path/to/virtualhost.sh
```

3. Optional: if you want to use the script globally, then you need to copy the file to your /usr/local/bin directory, is better
if you copy it without the .sh extension:

```bash
$ sudo cp /path/to/virtualhost.sh /usr/local/bin/virtualhost
```

### For Global Shortcut ###

```bash
$ cd /usr/local/bin
$ wget -O virtualhost https://raw.githubusercontent.com/charlybs/virtualhost/master/virtualhost.sh
$ chmod +x virtualhost
```

## Usage ##

Basic command line syntax:

```bash
$ sudo sh /path/to/virtualhost.sh [create | delete] [domain] [optional host_dir]
```

With script installed on /usr/local/bin:

```bash
$ sudo virtualhost [create | delete] [domain] [optional host_dir]
```


## Add LetsEncrypt CA cert ##

Add LetsEncrypt CA cert (install letsencrypt first) to your already created Virtual Host with https.

Add www. and non-www domains to fix security during the redirect (https://www.example.com -> https://example.com):

```bash
$ sudo letsencrypt -d www.example.com -d example.com
```

### Examples ###

to create a new virtual host:

```bash
$ sudo virtualhost create mysite.com
```
to create a new virtual host with custom directory name:

```bash
$ sudo virtualhost create anothersite.com /var/www/dev/
```
to delete a virtual host

```bash
$ sudo virtualhost delete mysite.dev
```

to delete a virtual host with custom directory name:

```
$ sudo virtualhost delete anothersite.dev /var/www/dev/
```
### Localization

Apache:

```bash
$ sudo cp /path/to/locale/<language>/virtualhost.mo /usr/share/locale/<language>/LC_MESSAGES/
```
