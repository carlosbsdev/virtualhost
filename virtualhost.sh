#!/bin/bash
### Set Language
TEXTDOMAIN=virtualhost

### Set default parameters
action=$1
domain=$2
rootDir=$3
owner=$(who am i | awk '{print $1}')
email=$4
https=$5
sitesEnable='/etc/apache2/sites-enabled/'
sitesAvailable='/etc/apache2/sites-available/'
userDir='/var/www/'
sitesAvailabledomain=$sitesAvailable$domain.conf

### don't modify from here unless you know what you are doing ####

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Use sudo"
		exit 1;
fi

if [ "$action" != 'create' ] && [ "$action" != 'delete' ]
	then
		echo $"You need to prompt for action (create or delete) -- Lower-case only"
		exit 1;
fi

while [ "$domain" == "" ]
do
	echo -e $"Please provide domain. example: test.com"
	read domain
done

if [ "$rootDir" == "" ]; then
	rootDir=${domain//./}
fi

### if root dir starts with '/', don't use /var/www as default starting point
if [[ "$rootDir" =~ ^/ ]]; then
	userDir=''
fi

rootDir=$userDir$rootDir

if [ "$action" == 'create' ]
	then
		### check if domain already exists
		if [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain already exists.\nPlease Try Another one"
			exit;
		fi
		
        while [ "$https" != 'n' ] && [ "$https" != 'y' ]
        do
	        echo -e $"Force domain to HTTPS? (Openssl self-signed cert) (y/n)"
	        read https
        done

        while [ "$email" == "" ]
        do
	        echo -e $"Please provide email. example: webmaster@localhost"
	        read email
        done
		
		### check if directory exists or not
		if ! [ -d $rootDir ]; then
			### create the directory
			mkdir $rootDir
			### give permission to root dir
			chmod 755 $rootDir
			### write test file in the new domain dir
			if ! echo "<?php echo phpinfo(); ?>" > $rootDir/index.php
			then
				echo $"ERROR: Not able to write in file $rootDir/index.php. Please check permissions"
				exit;
			else
				echo $"Added content to $rootDir/index.php"
			fi
		fi

        if [ "$https" == 'n' ] 
		    then
			### create virtual host rules file
		    if ! echo "
		    <VirtualHost $domain:80>
			    ServerAdmin $email
			    ServerName $domain
			    ServerAlias $domain
			    DocumentRoot $rootDir
				<Directory />
				    AllowOverride all
			    </Directory>
			    <Directory $rootDir>
				    Options FollowSymLinks
				    AllowOverride all
				    Require all granted
			    </Directory>
			    ErrorLog /var/log/apache2/$domain-error.log
			    LogLevel error
			    CustomLog /var/log/apache2/$domain-access.log combined
		    </VirtualHost>" > $sitesAvailabledomain
		    then
			    echo -e $"There is an ERROR creating $domain file"
			    exit;
		    else
			    clear
			    echo -e $"\nNew Virtual Host Created\nYour new host is: http://$domain \nAnd its located at $rootDir"
		    fi
		fi
		
		if [ "$https" == 'y' ] 
		    then
			### enable required modules for apache2 with https
			a2enmod headers
			a2enmod rewrite
			a2enmod ssl
			### create ssl self-signed cert
			mkdir /etc/apache2/ssl
			openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt
			
			### create virtual host rules file with https
		    if ! echo "
		    <VirtualHost $domain:80>
			    ServerAdmin $email
			    ServerName $domain
			    ServerAlias $domain
			    DocumentRoot $rootDir
			    <Directory />
				    AllowOverride all
			    </Directory>
			    <Directory $rootDir>
				    Options FollowSymLinks
				    AllowOverride all
				    Require all granted
			    </Directory>
			    ErrorLog /var/log/apache2/$domain-error.log
			    LogLevel error
			    CustomLog /var/log/apache2/$domain-access.log combined
			    Header always set Strict-Transport-Security \"max-age=63072000; includeSubDomains\"
			    #   Force redirect to https(port 443)
			    RewriteEngine on
			    RewriteCond %{SERVER_NAME} =$domain
			    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,QSA,R=permanent]
		    </VirtualHost>
			
		<IfModule mod_ssl.c>
            <VirtualHost $domain:443>
                ServerAdmin $email
                ServerName $domain
                DocumentRoot $rootDir
                Header always set Strict-Transport-Security \"max-age=63072000; includeSubDomains\"
                ErrorLog /var/log/apache2/$domain-error.log
			    LogLevel error
			    CustomLog /var/log/apache2/$domain-access.log combined
                #   Enable/Disable SSL for this virtual host.
                SSLEngine on
                SSLCertificateFile      /etc/apache2/ssl/apache.crt
                SSLCertificateKeyFile /etc/apache2/ssl/apache.key
                <FilesMatch \"\\.(cgi|shtml|phtml|php)$\">
                                SSLOptions +StdEnvVars
                </FilesMatch>
                <Directory /usr/lib/cgi-bin>
                                SSLOptions +StdEnvVars
                </Directory>
                BrowserMatch \"MSIE [2-6]\" \\
                                nokeepalive ssl-unclean-shutdown \\
                                downgrade-1.0 force-response-1.0
                # MSIE 7 and newer should be able to use keepalive
                BrowserMatch \"MSIE [17-9]\" ssl-unclean-shutdown
            </VirtualHost>
        </IfModule>" > $sitesAvailabledomain
		    then
			    echo -e $"There is an ERROR creating $domain file"
			    exit;
		    else
			    clear
			    echo -e $"\nNew Virtual Host Created\nYour new host is: https://$domain \nAnd its located at $rootDir"
		    fi
		fi
		

		### Add domain in /etc/hosts
		if ! echo "127.0.0.1	$domain" >> /etc/hosts
		then
			echo $"ERROR: Not able to write in /etc/hosts"
			exit;
		else
			echo -e $"Host added to /etc/hosts file \n"
		fi

		if [ "$owner" == "" ]; then
			chown -R $(whoami):$(whoami) $rootDir
		else
			chown -R $owner:$owner $rootDir
		fi

		### enable website
		a2ensite $domain

		### restart Apache
		/etc/init.d/apache2 restart

	else
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit;
		else
			### Delete domain in /etc/hosts
			newhost=${domain//./\\.}
			sed -i "/$newhost/d" /etc/hosts

			### disable website
			a2dissite $domain

			### restart Apache
			/etc/init.d/apache2 restart

			### Delete virtual host rules files
			rm $sitesAvailabledomain
		fi

		### check if directory exists or not
		if [ -d $rootDir ]; then
			echo -e $"Delete host root directory ? (y/n)"
			read deldir

			if [ "$deldir" == 'y' -o "$deldir" == 'Y' ]; then
				### Delete the directory
				rm -rf $rootDir
				echo -e $"Directory deleted"
			else
				echo -e $"Host directory conserved"
			fi
		else
			echo -e $"Host directory not found. Ignored"
		fi

		### show the finished message
		echo -e $"Complete!\nYou just removed Virtual Host $domain"
		exit 0;
fi
