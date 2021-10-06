#!/bin/bash
host=$(hostname)
a="$host.txt"
prefix=$(locate -b "\httpd.conf" | grep -v "tmp"| grep -v "sample" | egrep 'etc/httpd|etc/apache2')
if [[ $prefix ]];
then echo Apache configuration file -"$prefix- is found. CIS compliance output will now be written to $a file "
else echo "No prefix (httpd.conf) file found."
exit
fi


echo $(hostname) >>$a
echo -n "2.1 Ensure Only Necessary Authentication and Authorization Modules Are Enabled" >> $a

if httpd -M | grep -q 'auth._\|ldap'; then
  echo ":NOT COMPLIANT" >> $a
  echo "2.1 NOT COMPLIANT. Check if found auth modules are required. If not they need to be disabled"
else
  echo ":COMPLIANT" >> $a
fi 


echo -n "2.2 Ensure the Log Config Module Is Enabled" >> $a


if httpd -M | grep -q 'log_config'; then
  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
  echo "2.2 NOT COMPLIANT. Log Config is not Enabled"
fi


echo -n "2.3 Ensure the WebDAV Modules Are Disabled" >> $a


if httpd -M | grep -q 'dav_[[:print:]]+module'; then
  echo ":NOT COMPLIANT" >> $a
  echo "2.3 NOT COMPLIANT. Ensure webdav module is disabled"
else
  echo ":COMPLIANT" >> $a
fi




echo -n "2.4 Ensure the Status Module Is Disabled" >> $a


if httpd -M | grep -q 'status_module'; then
  echo ":NOT COMPLIANT" >> $a
  echo "2.4 NOT COMPLIANT. Ensure the status module is disabled"
else
  echo ":COMPLIANT" >> $a
fi


echo -n "2.5 Ensure the Autoindex Module Is Disabled" >> $a


if httpd -M | grep -q 'autoindex_module'; then
  echo ":NOT COMPLIANT" >> $a
  echo "2.5 NOT COMPLIANT. Ensure autoindex module is disabled"
else
  echo ":COMPLIANT" >> $a
fi


echo -n "2.6 Ensure the Proxy Modules Are Disabled" >> $a
if httpd -M | grep -q 'proxy_'; then
  echo ":NOT COMPLIANT" >> $a
  echo "2.6 NOT COMPLIANT. Ensure proxy module is disabled"
else
  echo ":COMPLIANT" >> $a
fi


echo -n "2.7 Ensure the User Directories Module Is Disabled" >> $a
if httpd -M | grep -q 'userdir_'; then
  echo ":NOT COMPLIANT" >> $a
  echo "2.7 NOT COMPLIANT. Ensure user directories module is disabled"
else
  echo ":COMPLIANT" >> $a
fi


echo -n "2.8 Ensure the Info Module Is Disabled" >> $a


if httpd -M | grep -q 'info_module'; then
  echo ":NOT COMPLIANT" >> $a
  echo "2.8 NOT COMPLIANT. Ensure info module is disabled"
else
  echo ":COMPLIANT" >> $a
fi


echo -n "2.9 Ensure the Basic and Digest Authentication Modules are Disabled" >> $a


if httpd -M | grep -q 'auth_basic_module\|auth_digest_module'; then
  echo ":NOT COMPLIANT" >> $a
  echo "2.9 NOT COMPLIANT. Ensure basic and digest auth. module is disabled"
else
  echo ":COMPLIANT" >> $a
fi


echo -n "3.1 Ensure the Apache Web Server Runs As a Non-Root User" >> $a
uidmin=$(grep '^UID_MIN' /etc/login.defs)
idapache=$(id apache)
if grep -i '^User apache' $prefix && grep -i '^Group apache' $prefix;
then  echo "3.1 User and group names configured correctly as apache." 
else echo "3.1 WARNING-User and group names for apache are not configured" 
fi
if [ $idapache -lt $uidmin ];
then echo "3.1 Apache user id is less than uidmin which is amazing" 
fi
if ps axu | grep hpd | grep -v '^root' 2>/dev/null;
then echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >>$a
     echo "3.1 NOT COMPLIANT. Apache runs as root user"
fi


echo -n "3.2 Ensure the Apache User Account Has an Invalid Shell" >> $a
if grep -i '^apache' /etc/passwd | grep nologin;
then  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
  echo "3.2 NOT COMPLIANT. Apache user has an invalid shell " 
fi


echo -n "3.3 Ensure the Apache User Account Is Locked" >> $a
if sudo passwd -S apache | grep locked;
then  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
  echo "3.3 NOT COMPLIANT. Ensure apache user is locked" 
fi


echo -n "3.4 Ensure Apache Directories and Files Are Owned By Root" >> $a
if find -type d -type f -path /var/www | /etc/httpd | /usr/sbin/httpd \! -user root -ls 2>/dev/null | grep  * ;
then echo ":NOT COMPLIANT" >>$a
     echo "3.4 NOT COMPLIANT. Make sure apache directories are owned by root"
else echo ":COMPLIANT">> $a
fi






echo -n "3.5 Ensure the Group Is Set Correctly on Apache Directories and Files" >> $a
folder="$(dirname $prefix)"
folder36="$(dirname $folder)"
if find -L $folder36 /etc/httpd/conf/htdocs -prune -o \! -group root -ls|grep * ;
then echo ":NOT COMPLIANT">> $a
      echo "3.5 NOT COMPLIANT. $folder36 does have files or dirs with non-root groups."
else echo ":COMPLIANT">> $a
fi


echo  -n "3.6 Ensure Other Write Access on Apache Directories and Files Is Restricted" >> $a
if find -L $folder36 \! -type l -perm /o=w -ls |grep *
then echo ":NOT COMPLIANT">> $a
 echo "$folder36 does have files or dirs writable by non-root."
else echo ":COMPLIANT">> $a
echo "$folder36 does not have files or dirs writable by non-root."
fi


echo -n "3.7 Ensure the Core Dump Directory Is Secured" >> $a
if cat $prefix |grep CoreDump* ;
then echo ":NOT COMPLIANT">> $a
     echo "3.7 NOT COMPLIANT. $prefix does have core file dump. Please remove the directive."
else echo ":COMPLIANT">> $a
fi




echo -n "3.8 Ensure the Lock File Is Secured" >> $a
if httpd -V | grep 'flock\|fcntl\|flock' ;
then echo ":NOT COMPLIANT" >> $a
     echo "3.8 NOT COMPLIANT. $prefix does have lock file directive. Please remove the directive." 
else echo ":COMPLIANT" >> $a
fi


echo -n "3.9 Ensure the Pid File Is Secured" >> $a


if grep -i "^pidfile" $prefix;
then pidfile=$(grep -i "^pidfile" $prefix | cut -d' ' -f2)
echo "3.9 $pidfile config found in your config file.Please remove it."  
else echo "3.9 OK. No pidfile configuration"
fi
if ls /$pidfile 2>/dev/null | /var/$pidfile 2>/dev/null;
then echo ":NOT COMPLIANT" >>$a
     echo "3.9 NOT COMPLIANT. $pidfile file exists. Please remove it."  
else echo ":COMPLIANT" >>$a
fi






echo -n "3.10 Ensure the ScoreBoard File Is Secured" >> $a


if grep -i "^ScoreBoardFile" $prefix;
then echo "3.10 $sbfile scoreboard file found."
sbfile=$(grep -i "^ScoreBoardFile" $prefix | cut -d' ' -f2)
sbstatus="NOT COMPLIANT"
else echo " 3.10 No scoraboardfile configuration was found"
sbstatus="COMPLIANT"
fi


if ls /$sbfile 2>/dev/null | /var/$sbfile 2>/dev/null;
then echo "$sbfile exists. Please remove it." 
sbstatus2="NOT COMPLIANT"
else echo "3.10 Scoreboard file does not exist." 
sbstatus2="COMPLIANT"
fi


if [[ "$sbstatus"=="COMPLIANT" && "$sbstatus2"=="COMPLIANT" ]]
then echo ":COMPLIANT" >>$a
else echo ":NOT COMPLIANT" >>$a
fi






echo -n "3.11 Ensure Group Write Access for the Apache Directories and Files Is Properly Restricted" >> $a


x=$(find -L $folder36 \! -type l -perm /g=w -ls 2>/dev/null)




if [ -n "$x" ];
then echo ":NOT COMPLIANT" >> $a
     echo "3.11 NOT COMPLIANT. There are files or dirs with group write access" 
else echo ":COMPLIANT" >> $a
fi




echo -n "3.12 Ensure Group Write Access for the Document Root Directories and Files Is Properly Restricted" >> $a
docroot=$(grep -i ^documentroot $prefix| cut -d' ' -f2)
GRP=$(grep '^Group' $prefix | cut -d' ' -f2)
if find -L $docroot -group $GRP -perm /g=w -ls;
then echo ":NOT COMPLIANT" >>$a
     echo "3.12 NOT COMPLIANT. There are files or dirs with apache group write access" 
else echo ":COMPLIANT" >>$a
fi


echo -n "4.1 Ensure Access to OS Root Directory Is Denied By Default" >> $a
if perl -ne 'print if /^ *<Directory *\//i .. /<\/Directory/i' $prefix | grep -E "Order allow,deny|Allow from all";
then echo ":NOT COMPLIANT" >> $a
     echo "4.1 NOT COMPLIANT. Root directory allows unauthorized access." 
else echo ":COMPLIANT" >> $a
fi


echo -n "4.2 Ensure Appropriate Access to Web Content Is Allowed" >> $a
conf=$(dirname $prefix)
conf42="$(dirname $conf)/conf.d/*.conf"
conf42b="$conf/*/*.conf"
if perl -ne 'print if /^ *<Directory *\/i .. /<\/Directory/i' $prefix $conf42 $conf42b | grep -v '^#'| grep -i -E 'Allow from|Require granted';
then echo ":NOT COMPLIANT" >>$a 
     echo "4.2 NOT COMPLIANT. Please check allowed hosts in directories -Allow from and Require Granted fields- in all your config files and make sure they do not allow from all"
else echo ":COMPLIANT" >>$a
fi


echo -n "4.3 Ensure OverRide Is Disabled for the OS Root Directory" >> $a


if  perl -ne 'print if /^ *<Directory *\/>/i .. /<\/Directory/i' $prefix $conf42 | grep -v '^#'| grep -i 'AllowOverrideList' ;
then echo ":NOT COMPLIANT" >>$a
     echo "4.3 NOT COMPLIANT. Please remove AllowOverrideList directive for OS root directory"
else echo ":COMPLIANT" >>$a 
fi


echo -n "4.4 Ensure OverRide Is Disabled for All Directories" >> $a


if  perl -ne 'print if /^ *<Directory *\/i .. /<\/Directory/i' $conf42b $prefix $conf42 | grep -v '^#'| grep -i 'AllowOverrideList' ;
then echo ":NOT COMPLIANT" >>$a
     echo "4.4 NOT COMPLIANT. Please remove AllowOverrideList directive in directives across all  directories"
else echo ":COMPLIANT" >> $a
fi




echo -n "5.1 Ensure Options for the OS Root Directory Are Restricted" >> $a
if perl -ne 'print if /^ *<Directory *\/>/i .. /<\/Directory/i' $prefix $conf42 | grep -v '^#'| grep -C 6 -i 'Options'|grep -v 'Options None';
then echo ":NOT COMPLIANT" >>$a 
     echo "5.1 NOT COMPLIANT. Please remove all Options directives except Options None"
else echo ":COMPLIANT" >>$a 
fi


echo -n "5.2 Ensure Options for the Web Root Directory Are Restricted" >> $a
if cat $prefix | grep  -C 6 -i '^<directory' | grep  -C 9 -i '$docroot'| grep -v '^#' |grep -i 'options' ;
#if perl -ne 'print if /^ *<Directory *\//i .. /<\/Directory/i' $prefix $conf42 | grep -v '^#'| grep -C 6 -i 'Options'|grep -v 'Options None'
then echo ":NOT COMPLIANT" >>$a
     echo "5.2 NOT COMPLIANT. Please remove all Options directives under web root except Options None"
# perl -ne 'print if /^ *<Directory *\//i .. /<\/Directory/i' $prefix $conf42 | grep -v '^#'| grep -C 6 -i 'Options'|grep -v 'Options None'>>$a
else echo ":COMPLIANT" >>$a
fi






echo -n "5.3 Ensure Options for Other Directories Are Minimized" >> $a
if cat $prefix $conf42 $conf42b | grep  -C 6 -i '^<directory' | grep -v '^#' |grep -i 'options' | grep -i "Includes" ;


then echo ":NOT COMPLIANT">>$a 
     echo "5.3 NOT COMPLIANT. Please remove all Options- Includes directives at all conf files"
else echo ":COMPLIANT" >>$a 


fi




echo -n "5.4 Ensure Default HTML Content Is Removed" >> $a
conf54=$(cat $conf42 $prefix | grep -i "^<Location")
file54=$(ls -alr $conf|grep -i *)


if $conf54 || $file54;
then echo ":NOT COMPLIANT">>$a 
     echo "5.4 NOT COMPLIANT. Please remove the files $file54 under $conf OR  $conf54 under $conf42 and $prefix" 
else echo ":COMPLIANT">>$a
fi


echo -n "5.5 Ensure the Default CGI Content printenv Script Is Removed" >> $a
dir55=$(cat $prefix | grep -i "^script*" |grep -v "^#" |cut -d'"' -f2)


if ls $dir55 |grep -i "printenv";
then echo ":NOT COMPLIANT">>$a 
     echo "5.5 NOT COMPLIANT. Please remove the conf listed here. $dir55/printenv"  
else echo ":COMPLIANT">>$a
fi




echo -n "5.6 Ensure the Default CGI Content test-cgi Script Is Removed" >> $a
dir55=$(cat $prefix | grep -i "^script*" |grep -v "^#" |cut -d'"' -f2)


if ls $dir55 |grep -i "test-cgi";
then echo ":NOT COMPLIANT">>$a 
     echo "5.6 NOT COMPLIANT. Please remove the conf listed here. $dir55/test-cgi"  
else echo ":COMPLIANT">>$a


fi




echo -n "5.7 Ensure HTTP Request Methods Are Restricted" >> $a
if  perl -ne 'print if /^ *<Directory *\/i .. /<\/Directory/i' $prefix $conf42 | grep -v '^#'| grep -i '<LimitExcept GET POST OPTIONS>' ;
then echo ":COMPLIANT">>$a
else echo ":NOT COMPLIANT">>$a
     echo "5.7 NOT COMPLIANT. Please add <LimitExcept GET POST OPTIONS> directive"
fi




echo -n "5.8 Ensure the HTTP TRACE Method Is Disabled" >> $a
if cat $prefix | grep -i "^TraceEnable off" ;
then echo ":COMPLIANT" >>$a
else echo ":NOT COMPLIANT">>$a 
     echo "5.8 NOT COMPLIANT. Please disable trace in your conf, adding 'TraceEnable off' line" 
fi


echo -n "5.9 Ensure Old HTTP Protocol Versions Are Disallowed " >> $a
if cat $prefix $conf42 $conf42b | grep -A 3  -i 'rewriteengine on'  | egrep -i  'RewriteCond %{THE_REQUEST} !HTTP/1\\.1\$|RewriteOptions Inherit';
then echo ":COMPLIANT" >>$a
else echo ":NOT COMPLIANT" >>$a
     echo "5.9 NOT COMPLIANT. Please add config so it rejects older http protocols"
fi


echo -n "5.10 Ensure Access to .ht* Files Is Restricted" >> $a


if cat $conf42 $prefix $conf42b |grep -A 2 -i 'filesmatch \"^\\.ht\"' |egrep -i 'Require all denied|Deny from All';
then echo ":COMPLIANT" >>$a
else echo ":NOT COMPLIANT" >>$a
     echo "5.10 NOT COMPLIANT. Please add config so it restricts access to .ht files" 
fi


echo -n "5.11 Ensure Access to Inappropriate File Extensions Is Restricted" >> $a
firstreq=$(cat $conf42 $prefix $conf42b | grep -A 2 -i 'filesmatch "^\.\*\$"'| egrep -i 'Require all denied|Deny from all')
secondreq=$(cat $conf42 $prefix $conf42b | grep -A 2 -i 'filesmatch "^\.\*\\\.(*'| egrep -i 'Require all granted|Allow from all')


if ($firstreq && $secondreq);
then echo ":COMPLIANT" >>$a
else echo ":NOT COMPLIANT" >>$a
     echo "5.11 NOT COMPLIANT. Please add config so it restricts unknown file extensions" 
fi


echo -n "5.12 Ensure IP Address Based Requests Are Disallowed" >> $a
if cat deneme | grep -A 4 -i "RewriteCond %{HTTP_HOST}" | grep -A 2 -i "RewriteCond %{REQUEST_URI}" | grep -i "RewriteRule ^.(.*)";
then echo ":COMPLIANT" >>$a
else echo ":NOT COMPLIANT" >>$a
     echo  "5.12 NOT COMPLIANT. Please add config so it restricts IP based access" 
fi


echo -n "5.13 Ensure the IP Addresses for Listening for Requests Are Specified" >> $a
if cat $prefix | grep -i '^listen'| egrep '80|0.0.0.0:80|[::ffff:0.0.0.0]:80';
then echo ":NOT COMPLIANT" >>$a
     echo "5.13 NOT COMPLIANT. You should specify an IP address to listen on. " 
else echo ":COMPLIANT" >>$a
fi


echo -n "5.14 Ensure Browser Framing Is Restricted" >> $a
if grep -i 'X-Frame-Options' deneme|grep -E 'Header always append X-Frame-Options SAMEORIGIN|Header always append X-Frame-Options DENY' 2>/dev/null;
then echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >>$a
     echo "5.14 NOT COMPLIANT. X-Frame-Options not enabled. Please enable it."  
fi




echo -n "6.1 Ensure the Error Log Filename and Severity Level Are Configured Correctly" >> $a
if cat $prefix|grep -i '^LogLevel' |grep -i 'notice core:info' 2>/dev/null;
then echo "6.1 Loglevel is at info level and this configuration is compliant"
else echo "6.1 Loglevel is not compliant.Please define loglevel line as notice core:info in httpd.conf"
fi
if cat $prefix|grep -i '^ErrorLog' |grep -i 'logs/error_log' 2>/dev/null;
then echo "6.1 Errorlog configuration is compliant."
else echo "6.1 Errorlog configuration is not compliant. Please define ErrorLog line as logs/error_log in httpd.conf"
fi


if cat $prefix|grep -i '^ErrorLog' |grep -i 'logs/error_log' &&  cat $prefix|grep -i '^LogLevel' |grep -i 'notice core:info' 2>/dev/null;
then echo ":COMPLIANT" >>$a
else echo ":NOT COMPLIANT" >>$a
     echo  "6.1 NOT COMPLIANT. error_log file is missing or loglevel is not defined as notice core info. " 
fi




echo -n "6.2 Ensure a Syslog Facility Is Configured for Error Logging" >> $a
if cat $prefix|grep -i '^ErrorLog' |grep -i 'syslog';
then echo ":COMPLIANT" >>$a
else echo ":NOT COMPLIANT" >>$a
     echo "6.2 NOT COMPLIANT. Please define a syslog line to send logs to a syslog server."
fi


echo -n "6.3 Ensure the Server Access Log Is Configured Correctly" >> $a
if cat $prefix | grep -i '^logformat'|grep -F '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined' 2>/dev/null
then echo "6.3 LogFormat is compliant" 
else echo "6.3 NOT COMPLIANT. LogFormat is not compliant.Please re-define logformat line in httpd.conf" 
fi
if cat $prefix | grep -i '^CustomLog'|grep -i 'combined' 2>/dev/null
then echo "6.3 Custom Log is combined and compliant." 
else echo "6.3 NOT COMPLIANT. Custom log is not compliant. Please re-define Custom Log line in httpd.conf"
fi
if cat $prefix | grep -i '^logformat'|grep -F '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined' && cat $prefix | grep -i '^CustomLog'|grep -i 'combined' 2>/dev/null
then echo ":COMPLIANT" >>$a
else echo ":NOT COMPLIANT" >>$a
     echo  "6.3 NOT COMPLIANT. Log format or custom log must be redefined. " 
fi


echo -n  "6.4 Ensure Log Storage and Rotation Is Configured Correctly" >> $a
logr1=/etc/logrotate.conf
logr2=/etc/logrotate.d/httpd


if cat $logr1 $logr2 |grep -i 'rotate' |egrep '[1-9][0-9]'| egrep -v '10$|11$|12$';
then echo "6.4  Your log retention period is COMPLIANT i.e. equal to or larger than 13 weeks."  
logretention="COMPLIANT"
else echo "6.4 NOT COMPLIANT. Please arrange log retention for larger than or equal to 13 weeks"  
logretention="NOT-COMPLIANT"
fi
if cat $logr1 $logr2 | grep -i '^weekly' 2>/dev/null;
then echo "6.4  Weekly rotation of logs is compliant"  
logrotation="COMPLIANT"
else echo "6.4 NOT COMPLIANT. Please adjust for weekly log rotation" 
logrotation="NOT-COMPLIANT"
fi
if cat $logr1 $logr2 | grep -i 'postrotate' 2>/dev/null;
then echo "6.4  Your log rotation config is compliant"  
logconfig="COMPLIANT"
else echo "6.4 NOT COMPLIANT. Please adjust your log rotation config. +add postrotate"  
logconfig="NOT-COMPLIANT"
fi
if [ '$logconfig'="COMPLIANT" && '$logrotation'="COMPLIANT" && '$logretention'="COMPLIANT" ];
then echo ":COMPLIANT" >>$a
else echo ":NOT COMPLIANT" >> $a
fi


#Manual check required for 6.5
echo -n "6.5 Ensure Applicable Patches Are Applied" >> $a
echo  ":NOT APPLICABLE" >> $a


echo -n "6.6 Ensure ModSecurity Is Installed and Enabled" >> $a
if httpd -M |grep -i 'security2_mod' 2>/dev/null;
then echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >> $a
     echo "6.6 NOT COMPLIANT. Mod security is not installed" 
fi




echo -n "6.7 Ensure the OWASP ModSecurity Core Rule Set Is Installed and Enabled" >> $a


if locate mod_security.conf;
then echo ":COMPLIANT" >> $a
     echo "6.7 COMPLIANT. Mod Security configuration file found. Please verify manually if Mod Security core rule set is deployed." 
else echo ":NOT COMPLIANT" >> $a
     echo "6.7 NOT COMPLIANT. Mod Security config file is not found." 
fi


echo -n "7.1 Ensure mod_ssl and/or mod_nss Is Installed" >> $a
sslmodule=$(httpd -M | egrep 'ssl_module|nss_module')
if httpd -M | egrep 'ssl_module|nss_module';
then echo ":COMPLIANT" >>$a
else echo ":NOT COMPLIANT" >>$a
     echo "7.1 NOT COMPLIANT. SSL is not installed." 
fi




echo -n "7.2 Ensure a Valid Trusted Certificate Is Installed" >> $a
if openssl verify -CAfile /etc/pki/tls/certs/ca-bundle.crt -purpose sslserver /etc/pki/tls/certs/ |grep -i 'error';
then echo ":NOT COMPLIANT" >> $a
else echo ":COMPLIANT" >>$a
fi


altconf="$(locate "ssl.conf" | grep -i apache)"
echo -n "7.3 Ensure the Server's Private Key Is Protected" >> $a
crtfiles="$(cat $prefix $conf42 $conf42b $altconf |grep -i sslcertificatefile |grep -v '^#'|cut -d'/' -f2-7 | xargs -I "%" echo /%)"
crtkeyfile="$(cat $prefix $conf42 $conf42b $altconf | grep -i sslcertificatekeyfile |grep -v '^#'|cut -d'/' -f2-7 | xargs -I "%" echo /%)"


checkpk=$(cat $prefix $conf42 $conf42b $altconf | grep -i sslcertificatekeyfile |grep -v '^#')
if [ "$checkpk" ];
then echo "7.3 First part COMPLIANT. You have a separate private key file configured." 
else echo "7.3 First part NOT COMPLIANT. You should add a separate key file for private key in Apache config."
fi


checkcrt=$(cat $crtfiles | grep -i 'Private KEY---')
if [ "$checkcrt" ];
then echo "7.3 Second part NOT COMPLIANT. Looks like you keep private key within cert file." 
else echo "7.3 Second part COMPLIANT. There is no private key in configured cert files." 
fi
check1="$(find $crtkeyfile \! -user root -ls)"


if [ "$check1" ];
then echo "7.3 Third part NOT COMPLIANT. Crt key files should be owned by root" 
else echo "7.3 Third part COMPLIANT. Crt key files are owned by root." 
fi


check2="$(find $crtkeyfile \! -perm 400 -ls)"


if [ "$check2" ];
then echo "7.3 Fourth part NOT COMPLIANT. Crt key files should be  0400 perm.set only" 
else echo "7.3 Fourth part COMPLIANT. Crt key files are set 0400 permission."  
fi


if [ "$check1" || "$check2" || "$checkcrt" || "!$checkpk" ];
then echo ":NOT COMPLIANT" >> $a
else echo ":COMPLIANT" >> $a
fi


echo -n "7.4 Ensure Weak SSL Protocols Are Disabled" >> $a
if cat  $prefix $conf42 $conf42b $altconf| grep -i '^sslprotocol all'| grep -v '\-SSLv3';
then echo ":NOT COMPLIANT" >>$a
echo "7.4 NOT COMPLIANT. You have enabled sslv3. Please disable it." 
elif cat  $prefix $conf42 $conf42b $altconf | grep -i '^sslprotocol'| grep -i -v 'all' |grep -v 'SSLv3';
then echo ":COMPLIANT" >> $a
echo "7.4 Good. You explicitly enabled non sslv3 protocols in at least one of your ssl configurations." 
elif cat  $prefix $conf42 $conf42b $altconf | grep -i '^sslprotocol'| grep -i  'all' |grep -i '\-SSLv3';
then echo ":COMPLIANT" >> $a
echo "7.4 Good. You explicitly disabled sslv3 protocols in at least one of your ssl configurations." 
else echo ":Manual review required" >> $a
echo "7.4 Manual review required."
fi


echo -n "7.5 Ensure Weak SSL/TLS Ciphers Are Disabled" >> $a
cipherorder=$(cat  $prefix $conf42 $conf42b $altconf| grep -i 'sslhonorcipherorder on'|grep -v '#')
if cat  $prefix $conf42 $conf42b $altconf | grep -i 'sslhonorcipherorder on'|grep -v '#' 2>/dev/null;
then echo "7.5 Good - You have ssl cipher order enabled" 
else echo "7.5 NOT COMPLIANT ssl order of cipher disabled." 
echo "Please enable Cipher Order." 
fi
weakciphers="$(cat $prefix $conf42 $conf42b $altconf | grep -v '#' | grep -A 5 -i 'sslciphersuite' |awk '/!EXP/&& /!NULL/ && /!LOW/ && /!SSLv2/ && /!MD5/ && /!RC4/ && /!aNULL/')"
if [ "$weakciphers" ];
 then echo "7.5 Good. You have disabled weak cipher suites." 
 else echo "7.5 NOT COMPLIANT. You have to disable weak tls/ssl cipher suites."  
fi


if [[ "$weakciphers" && "$cipherorder" ]]
then echo ":COMPLIANT" >>$a
else echo ":NOT COMPLIANT" >>$a
fi






echo -n "7.6 Ensure Insecure SSL Renegotiation Is Not Enabled" >> $a


if cat  $prefix $conf42 $conf42b $altconf | grep -i 'sslinsecurerenegotiation on'|grep -v '#';
then echo ":NOT COMPLIANT" >>$a
echo "7.5 NOT COMPLIANT. Please turn off ssl insecure renegotiation" 
else echo ":COMPLIANT" >>$a
fi


echo -n "7.7 Ensure SSL Compression is not Enabled" >> $a
if cat  $prefix $conf42 $conf42b $altconf | grep -i 'sslcompression on'|grep -v '#';
then echo ":NOT COMPLIANT" >> $a
echo "7.7. NOT COMPLIANT. Please turn off ssl compression"
else echo ":COMPLIANT" >> $a
fi


echo -n  "7.8 Ensure Medium Strength SSL/TLS Ciphers Are Disabled" >> $a
medciphers="$(cat $prefix $conf42 $conf42b $altconf | grep -v '#' | grep -A 5 -i 'sslciphersuite' |awk '/!3DES/ && /!IDEA/')"
if [ "$medciphers" ];
 then echo ":COMPLIANT" >> $a
 else echo ":NOT COMPLIANT" >> $a
      echo "7.8 NOT COMPLIANT. You have to disable MEDIUM strength tls/ssl cipher suites."  
fi






echo -n "7.9 Ensure the TLSv1.0 Protocol is Disabled" >> $a


if cat  $prefix $conf42 $conf42b $altconf| grep -i 'sslprotocol'|grep -v '#' | grep -i -v 'all' |grep -v 'TLSv1.0';
then echo ":COMPLIANT" >> $a
elif cat $prefix $conf42 $conf42b $altconf| grep -i 'sslprotocol'|grep -v '#'| grep -i 'all' |grep -i '\-TLSv1.0';
then echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >> $a
     echo "7.9 NOT COMPLIANT. Please ensure that TLS v.1.0 is disabled"
fi


echo -n "7.10 Ensure OCSP Stapling Is Enabled" >> $a
if cat  $prefix $conf42 $conf42b $altconf | grep -A 5 -B 5 -i 'sslStaplingCache'|grep -i 'SSLUseStapling on'|grep -v '#';
then echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >>$a
     echo "7.10 NOT COMPLIANT . Please enable OCSP stapling cache and use it." 
fi


echo -n "7.11 Ensure HTTP Strict Transport Security Is Enabled" >> $a
if cat  $prefix $conf42 $conf42b $altconf| grep -i 'Header always set Strict-Transport-Security'|grep -v '#';
then echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >> $a
     echo "7.11 NOT COMPLIANT. Please enable HSTS."


fi




echo -n "8.1 Ensure ServerTokens is Set to Prod or ProductOnly" >> $a
if cat  $prefix $conf42 $conf42b $altconf| grep -i 'ServerTokens'|grep -i -e 'prod' -e 'ProductOnly'| grep -v '#';
then echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >> $a
     echo "8.1 NOT COMPLIANT. Please set ServerTokens in prod only mode."


fi


echo -n "8.2 Ensure ServerSignature Is Not Enabled" >> $a
if cat  $prefix $conf42 $conf42b | grep -i 'ServerSignature on'| grep -v '#' 2>/dev/null;
then echo ":NOT COMPLIANT" >> $a
     echo "8.2. NOT COMPLIANT. Your ServerSignature is on ." 
else echo ":COMPLIANT" >> $a 
fi


echo -n "8.3 Ensure All Default Apache Content Is Removed" >> $a
if cat  $prefix $conf42 $conf42b | grep -i 'Include conf/extra/httpd-autoindex.conf'| grep -v '#' 2>/dev/null;
then echo ":NOT COMPLIANT" >> $a
echo "8.3 NOT COMPLIANT. Apache default content is on ."
elif cat $prefix $conf42 $conf42b| grep -A 8 -i 'ALIAS /ICONS/' | grep -v '#' 2>/dev/null;
then echo ":NOT COMPLIANT" >> $a
     echo "8.3 NOT COMPLIANT. Apache default content is on ." 
else echo ":COMPLIANT" >> $a
fi


echo -n "8.4 Ensure ETag Response Header Fields Do Not Include Inodes" >> $a
if cat  $prefix $conf42 $conf42b | grep -i 'FileETag'| grep -i -e 'all|inode|+inode' |grep -v '#';
then echo ":NOT COMPLIANT" >> $a
     echo "8.4 NOT COMPLIANT. You do have file etag directive in either inode or all mode. Please remove the directive or set it to none or MTime Size."
else echo ":COMPLIANT" >> $a
fi


echo -n  "9.1 Ensure the TimeOut Is Set to 10 or Less" >> $a
if cat  $prefix $conf42 $conf42b | grep -i -x 'Timeout 10' |grep -v '#';
then echo ":COMPLIANT" >> $a
elif cat  $prefix $conf42 $conf42b | grep -i 'Timeout' |grep -v '#'|egrep '\b[0-9]\b';
then echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >> $a
     echo "9.1 NOT COMPLIANT. Please configure server timeout to 10 seconds or less to stand against Dos attacks" 
fi


echo -n "9.2 Ensure KeepAlive Is Enabled" >> $a
if cat  $prefix $conf42 $conf42b | grep -x -i 'KeepAlive off';
then echo ":NOT COMPLIANT" >> $a
echo "9.2 NOT COMPLIANT. Please turn on keepalive "
else echo ":COMPLIANT" >> $a
fi




echo -n "9.3 Ensure MaxKeepAliveRequests is Set to a Value of 100 or Greater" >> $a
if cat  $prefix $conf42 $conf42b |grep -i 'maxkeepaliverequests' |grep -v '#'|egrep '\b[1-9][0-9]\b|\b[1-9]\b';
then echo ":NOT COMPLIANT" >> $a
echo "9.3 NOT COMPLIANT. Maxkeepaliverequest must be 100 or more" 
else echo ":COMPLIANT" >> $a
fi




echo -n "9.4 Ensure KeepAliveTimeout is Set to a Value of 15 or Less" >> $a
kato=$(cat  $prefix $conf42 $conf42b |grep -i 'keepalivetimeout' |grep -v '#'|cut -d' ' -f2)
if [[ $kato -gt 15 ]];
then echo ":NOT COMPLIANT" >> $a
     echo "9.4 NOT COMPLIANT. Keep alive timeout must be 15 or less" 
else echo ":COMPLIANT" >> $a
fi




echo -n "9.5 Ensure the Timeout Limits for Request Headers is Set to 40 or Less" >> $a
rrth=$(cat  $prefix $conf42 $conf42b |grep -i 'requestreadtimeout' |grep -v '#'|cut -d'-' -f2|cut -d',' -f1)
if [[ $rrth -gt 40 ]];
then echo ":NOT COMPLIANT" >> $a
     echo "9.5 NOT COMPLIANT. Request read timeout for header must be 40 or less" 
else echo ":COMPLIANT" >> $a
fi




echo -n "9.6 Ensure Timeout Limits for the Request Body is Set to 20 or Less" >> $a
rrtb=$(cat  $prefix $conf42 $conf42b | grep -i 'requestreadtimeout' |grep -i -o 'body=.*,'|cut -d'=' -f2|cut -d',' -f1)
if [[ $rrtb -gt 20 ]];
then echo ":NOT COMPLIANT" >> $a
     echo "9.6 NOT COMPLIANT. Request read timeout for body must be 20 or less" 
else echo ":COMPLIANT" >> $a
fi 


echo -n "10.1 Ensure the LimitRequestLine directive is Set to 512 or less" >> $a
lrl=$(cat  $prefix $conf42 $conf42b |grep -i 'limitrequestline' |grep -v '#'|cut -d'-' -f2|cut -d',' -f1)
if [[ $lrl -gt 512 ]];
then echo ":NOT COMPLIANT" >> $a
     echo "10.1 NOT COMPLIANT. Limit request line must be 512 or less"
else echo ":COMPLIANT" >> $a
fi


echo -n "10.2 Ensure the LimitRequestFields Directive is Set to 100 or Less" >> $a
lrf=$(cat  $prefix $conf42 $conf42b |grep -i 'limitrequestfields' |grep -v '#'|cut -d'-' -f2|cut -d',' -f1)
if [[ $lrf -gt 100 ]];
then echo ":NOT COMPLIANT" >> $a
     echo "10.2 NOT COMPLIANT. Limit request fields must be 100 or less" 
else echo ":COMPLIANT" >> $a
fi


echo -n "10.3 Ensure the LimitRequestFieldsize Directive is Set to 1024 or Less" >> $a
lrfs=$(cat  $prefix $conf42 $conf42b |grep -i 'limitrequestfieldsize' |grep -v '#'|cut -d'-' -f2|cut -d',' -f1)
if [[ $lrfs -gt 1024 ]];
then echo ":NOT COMPLIANT" >> $a
     echo "10.3 NOT COMPLIANT. Limit request field size must be 1024 or less" 
else echo ":COMPLIANT" >> $a
fi


echo -n "10.4 Ensure the LimitRequestBody Directive is Set to 102400 or Less" >> $a
lrb=$(cat  $prefix $conf42 $conf42b |grep -i 'limitrequestbody' |grep -v '#'|cut -d'-' -f2|cut -d',' -f1)
if [[ $lrb -gt 102400 ]];
then echo ":NOT COMPLIANT" >> $a
     echo "10.4 NOT COMPLIANT.limit request body size must be 102400 or less" 
else echo ":COMPLIANT" >> $a
fi




echo  -n "11.1 Ensure SELinux Is Enabled in Enforcing Mode" >> $a


if sestatus | grep -i mode;
then echo "You enabled SELinux"
if sestatus |grep -i mode| grep enforcing;
then echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >> $a 
     echo "11.1 NOT COMPLIANT. Please enforce SELinux."  
fi


echo -n "11.2 Run Apache Processes in the httpd_t Confined Context" >> $a
if ps -eZ | grep 'httpd' | grep -v httpd_t;
then
echo ":NOT COMPLIANT" >> $a 
echo "11.2 NOT COMPLIANT. Not all processes are confined to httpd_t" 
else echo ":COMPLIANT" >> $a
fi


echo -n "11.3 Ensure the httpd_t Type is Not in Permissive Mode" >>$a
if semodule -l | grep -i "permissive httpd_t";
then echo ":NOT COMPLIANT" >> $a
     echo "There should be no output for permissive httpd_t" 
else echo ":COMPLIANT" >> $a
fi


echo -n "11.4 Ensure Only the Necessary SELinux Booleans are Enabled -NOT SCORED-" >>$a
if getsebool -a | grep httpd_ | grep '> on';
then echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >> $a 
     echo "11.4 NOT COMPLIANT. SELINUX BOOLEANS NOT ENABLED" 

fi


else echo  ":11.1, 11.2, 11.3 and 11.4 -NOT SCORED- are NOT APPLICABLE.SELinux not enabled" >> $a
fi


echo -n "12.1 Enable the AppArmor Framework" >>$a
if ps -eZ |grep apache2;
then echo "You are running Ubuntu and you should enable AppArmor for security" 
if aa-status --enabled && echo Enabled;
then echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >>$a 
     echo "12.1 NOT COMPLIANT. AppArmor is not ENABLED" 
fi


echo -n "12.2 Customize the Apache AppArmor Profile -Not Scored-" >>$a
if cat /etc/apparmor.d/usr.sbin.apache2 /etc/apparmor.d/apache2.d/* /etc/apparmor.d/abstractions/* | grep '\/\*\*';
then echo ":NOT COMPLIANT" >>$a
     echo "12.2 -not scored- NOT COMPLIANT.Profile is overpermissive." 
else echo ":COMPLIANT" >> $a
fi


echo -n "12.3 Ensure Apache AppArmor Profile is in Enforce Mode" >>$a
if aa-unconfined --paranoid | grep apache2 | egrep -v 'confined|enforce';
then echo ":NOT COMPLIANT" >> $a
     echo "12.3 NOT COMPLIANT. PLease check and enforce policy" 
else echo ":COMPLIANT" >> $a
fi
echo
else echo ":12.1, 12.2 and 12.3 is NOT APPLICABLE since the system does not seem to be running on Ubuntu" >> $a
fi


exit
 636  tomcat-cis controls.txt 
@@ -0,0 +1,636 @@
﻿#!/bin/bash


host=$(hostname)
a="$host.txt"
prefix=$(sudo locate server.xml | grep -i tomcat)
conf="$(dirname $prefix)"
home="$(dirname $conf)"
admin=$(stat -c "%U" $home)
group=$(stat -c "%G" $home)
webxml=$(sudo locate web.xml | grep -i tomcat)
context=$(sudo locate context.xml |grep tomcat)


if [[ $prefix ]];
then echo "Tomcat configuration file -\$prefix- is found. CIS compliance output will now be written to $a file "
else echo "No prefix \(server.xml\) file found."
exit
fi


echo $(hostname) >>$a
echo -n "1.1 Remove extraneous files and directories \(Scored\)" >> $a

if ls -l $home/webapps/examples \;
then  
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "1.2 Disable Unused Connectors \(Not Scored\)" >> $a


if cat $prefix | grep -i "Connector port="8443"" ; then
  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
fi


jarfile="$conf/lib/catalina.jar"
jarexe="$(sudo locate /jdk/bin/jar | grep -m1 "")"
serverinfo="org/apache/catalina/util/ServerInfo.properties"
$jarexe xf $jarfile $serverinfo


echo -n "2.1 Alter the Advertised server.info String \(Scored\)" >> $a
if cat $serverinfo | grep -i "server.info=" | egrep "8.|7." ; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi




echo -n "2.2 Alter the Advertised server.number String \(Scored\)" >> $a


if cat $serverinfo | grep -i "server.number=" | egrep "8.|7." ; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "2.3 Alter the Advertised server.built Date \(Scored\)" >> $a


if cat $serverinfo | grep -i "server.built\=" | grep "20\*" ; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "2.4 Disable X-Powered-By HTTP Header and Rename the Server Value for all Connectors \(Scored\)" >> $a


if cat $prefix | grep -i "xpoweredBy=\"true\""  ; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "2.5 Disable client facing Stack Traces \(Scored\)" >> $a
if cat $webxml | grep -i -A 10 "<error-page>" | grep -i -A 10 "<exception-type>" | grep -i "<java.lang.Throwable>"  ; then
  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
fi


echo -n "2.6 Turn off TRACE \(Scored\)" >> $a


if cat $prefix | grep -i "allow.Trace="true""  ; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "2.7 Ensure Sever Header is Modified To Prevent Information Disclosure \(Not Scored\)" >> $a


if cat $prefix  |grep "server=*" |egrep -i "tomcat|Apache"  ; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "3.1 Set a nondeterministic Shutdown command value \(Scored\)" >> $a


if cat $prefix  |grep -i shutdown=\"shutdown\"  ; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "3.2 Disable the Shutdown port \(Not Scored\)" >> $a


if cat $prefix  |grep -i shutdown=\"shutdown\" | grep -i port=\"-1\" ; then
  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
fi


echo -n "4.1 Restrict access to $CATALINA_HOME \(Scored\)" >> $a


if  find $home -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "4.2 Restrict access to $CATALINA_BASE \(Scored\)" >> $a


if  find $base -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "4.3 Restrict access to Tomcat configuration directory \(Scored\)" >> $a


if  find $conf -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat_admin -o ! -group tomcat \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "4.4 Restrict access to Tomcat logs directory \(Scored\)" >> $a


if  find $home/logs -follow -maxdepth 0 \( -perm /o+rwx -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi




echo -n "4.5 Restrict access to Tomcat temp directory \(Scored\)" >> $a


if  find $home/temp -follow -maxdepth 0 \( -perm /o+rwx -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "4.6 Restrict access to Tomcat binaries directory \(Scored\)" >> $a


if  find $home/bin -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "4.7 Restrict access to Tomcat webapp directory \(Scored\)" >> $a


if  find $home/webapps -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "4.8 Restrict access to Tomcat Catalina properties file \(Scored\)" >> $a


if  find $conf/catalina.properties -follow -maxdepth 0 \( -perm /o+rwx,g+rwx,u+x -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "4.9 Restrict access to Tomcat Catalina policy file \(Scored\)" >> $a


if  find $conf/catalina.policy -follow -maxdepth 0 \( -perm /o+rwx,g+rwx,u+x -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi




echo -n "4.10 Restrict access to Tomcat context.xml \(Scored\)" >> $a


if  find $context -follow -maxdepth 0 \( -perm /o+rwx,g+rwx,u+x -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "4.11 Restrict access to Tomcat logging.properties \(Scored\)" >> $a


if  find $conf/logging.properties -follow -maxdepth 0 \( -perm /o+rwx,g+rwx,u+x -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "4.12 Restrict access to Tomcat server.xml \(Scored\)">> $a


if  find $prefix -follow -maxdepth 0 \( -perm /o+rwx,g+rwx,u+x -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "4.13 Restrict access to Tomcat tomcat-users.xml \(Scored\)">> $a


if  find $conf/tomcat-users.xml -follow -maxdepth 0 \( -perm /o+rwx,g+rwx,u+x -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "4.14 Restrict access to Tomcat web.xml \(Scored\)">> $a


if  find $webxml -follow -maxdepth 0 \( -perm /o+rwx,g+rwx,u+x -o ! -user $admin -o ! -group $group \) -ls; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi




echo -n "5.1 Use secure Realms \(Scored\)">> $a


if  cat $prefix | grep -i "classname" | egrep "MemoryRealm|JDBCRealm|UserDatabaseRealm"; then
  echo ":NOT COMPLIANT" >> $a
else
  echo ":COMPLIANT" >> $a
fi


echo -n "5.2 Use LockOut Realms \(Scored\)">> $a


if  cat $prefix | grep -i "classname" | grep "LockoutRealm" | grep -i "failureCount=\"3\"" |grep -i "lockOutTime=\"600\""; then
  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
fi


echo -n "6.1 Setup Client-cert Authentication \(Scored\)">> $a


if  cat $prefix | grep -i -A 9 "<connector" | grep -i -A 9 "clientauth=\"true\"" | grep -i certificateverification=\"required\"; then
  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
fi


echo -n "6.2 Ensure SSLEnabled is set to True for Sensitive Connectors \(Not Scored\)">> $a


if  cat $prefix | grep -i -A 9 "<connector" | grep -i -A 9 "sslenabled=\"true\""; then
  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
fi


echo -n "6.3 Ensure scheme is set accurately \(Scored\)">> $a


if  cat $prefix | grep -i -A 9 "<connector" | grep -i -A 9 "sslenabled=\"true\" | grep -i scheme=\"https\""; then
  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
fi


echo -n "6.4 Ensure secure is set to true only for SSL-enabled Connectors \(Scored\)">> $a


if  cat $prefix | grep -i -A 9 "<connector" | grep -i -A 9 "sslenabled=\"true\" | grep -i secure=\"true\""; then
  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
fi


echo -n "6.5 Ensure SSL Protocol is set to TLS for Secure Connectors \(Scored\)">> $a


if  cat $prefix | grep -i -A 9 "<connector" | grep -i -A 9 "sslenabled=\"true\" | grep -i sslprotocol=\"tls\""; then
  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
fi


echo -n "6.6 Control the maximum size of a POST request that will be parsed for parameter \(Scored\)">> $a


# if sudo cat $prefix |tr -d '\n' | perl -l -ne 'for (m{<Connector.*?</Connector>}gs) {print if /\maxpostsize=2097152/}';
# then echo ":COMPLIANT" >> $a


if cat $prefix | grep -q "maxpostsize";then
echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >>$a
fi


echo -n "7.1 Application specific logging \(Scored\)">> $a


if  ls -lra $home/webapps/APP/WEB-INF/classes | grep -i logging.properties; then     
  echo ":COMPLIANT" >> $a
else
  echo ":NOT COMPLIANT" >> $a
fi


echo -n "7.2 Specify file handler in logging.properties files \(Scored\)">> $a


if cat $home/webapps/APP/WEB-INF/classes/logging.properties | grep handlers; then
echo ":COMPLIANT" >> $a
elif cat $conf/logging.properties | grep handlers;
then echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT">> $a


fi


echo -n "7.3 Ensure className is set correctly in context.xml \(Scored\)">> $a


if  cat $context | grep org.apache.catalina.valves.AccessLogValve; then
  echo ":COMPLIANT" >> $a
else  echo ":NOT COMPLIANT" >> $a


fi


echo -n "7.4 Ensure directory in context.xml is a secure location \(Scored\)">> $a
loglocation=$(cat $conf/context.xml | grep directory | cut -d '"' -f 2)
if  find $home/logs -maxdepth 0 \( -perm /o+rwx -o ! -user $admin -o ! -group $group \) -ls ; then
  echo ":NOT COMPLIANT" >> $a
else  echo ":COMPLIANT" >> $a


fi


echo -n "7.5 Ensure pattern in context.xml is correct \(Scored\)">> $a


if  cat $home/webapps/APP/META-INF/context.xml | grep pattern; then
  echo ":COMPLIANT" >> $a
else  echo ":NOT COMPLIANT" >> $a
fi


echo -n "7.6 Ensure directory in logging.properties is a secure location \(Scored\)">> $a


if  find $home/logs -maxdepth 0 \( -perm /o+rwx -o ! -user $admin -o ! -group $group \) -ls ; then
  echo ":NOT COMPLIANT" >> $a
else  echo ":COMPLIANT" >> $a
fi




echo -n "8.1 Restrict runtime access to sensitive packages \(Scored\)">> $a


if  cat $conf/catalina.properties | grep -i "package.access=sun.,org.apache.catalina.,org.apache.coyote.,org.apache.jasper.,org.apache.tomcat." ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


echo -n "9.1 Starting Tomcat with Security Manager \(Scored\)">> $a


if  cat /etc/init.d/gcstartup |grep -i catalina | grep -i "-security" ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


echo -n "9.2 Disabling auto deployment of applications \(Scored\)">> $a


if  cat $prefix |grep -i "autodeploy=\"false\"" ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


echo -n "9.3 Disable deploy on startup of applications \(Scored\)">> $a


if  cat $prefix |grep -i "deployonstartup=\"false\"" ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.1 Ensure Web content directory is on a separate partition from the Tomcat system files \(Not Scored\)">> $a


if  ls -l $home/webapps ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.2 Restrict access to the web administration application \(Not Scored\)">> $a


if sudo cat $prefix | grep -i "<valve" | grep -v "<!--" | grep -i remoteaddrvalve ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.3 Restrict manager application \(Not Scored\)">> $a
manager="$(locate manager.xml | grep tomcat)"


if [[ !$manager ]]; then 
echo ":NOT APPLICABLE" >> $a
elif sudo cat $manager | grep -i "<valve" | grep -v "<!--" | grep -i allow ; then
echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.4 Force SSL when accessing the manager application \(Scored\)">> $a


if sudo cat $webxml | grep -i "transport-guarantee" | grep -i confidential ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.5 Rename the manager application \(Scored\)">> $a


if  [ $manager ] ; then
  echo ":NOT COMPLIANT" >> $a
  else echo ":COMPLIANT" >> $a
fi


echo -n "10.6 Enable strict servlet Compliance \(Scored\)">> $a
startup="$(locate catalina.sh | grep tomcat)"
if [[ !$startup ]];
then echo ":NOT APPLICABLE" >> $a
elif sudo cat $startup | grep -i "\-dorg.apache.catalina.strict_servlet_compliance\=true" ; then
echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.7 Turn off session facade recycling \(Scored\)">> $a
if [[ !$startup ]];
then echo ":NOT APPLICABLE" >> $a
elif sudo cat $startup | grep -i "-Dorg.apache.catalina.connector.RECYCLE_FACADES=true" ; then
echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.8 Do not allow additional path delimiters \(Scored\)">> $a
if [[ !$startup ]];
then echo ":NOT APPLICABLE" >> $a
elif sudo cat $startup | grep -A 10 -B 10 -i "-Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=false" | grep -i "-Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=false" ; then
echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.9 Do not allow custom header status messages \(Scored\)">> $a
if [[ !$startup ]];
then echo ":NOT APPLICABLE" >> $a
elif sudo cat $startup | grep -i "-Dorg.apache.coyote.USE_CUSTOM_STATUS_MSG_IN_HEADER=false" ; then
echo ":COMPLIANT" >> $a
else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.10 Configure connectionTimeout \(Scored\)">> $a
to=$(cat $prefix | grep -i connectiontimeout | cut -d """ -f2 | cut -d """ -f1)
if  [[ $to -gt 60000 ]]  ; then
echo ":NOT COMPLIANT" >> $a
else echo ":COMPLIANT" >> $a
fi


echo -n "10.11 Configure maxHttpHeaderSize \(Scored\)">> $a
maxhttphs=$(cat $prefix | grep -i maxhttpheadersize | cut -d """ -f2 | cut -d """ -f1)
if  [[ $maxhttphs -eq 8192 ]]  ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.12 Force SSL for all applications \(Scored\)">> $a


if  cat $webxml | grep -i "transport-guarantee" | grep -i confidential ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.13 Do not allow symbolic linking \(Scored\)">> $a


if  sudo cat $context | grep -i "allowlinking=\"true\""  ; then
  echo ":NOT COMPLIANT" >> $a
  else echo ":COMPLIANT" >> $a
fi


echo -n "10.14 Do not run applications as privileged \(Scored\)">> $a
if  sudo cat $context | grep -i "privileged=\"true\""  ; then
  echo ":NOT COMPLIANT" >> $a
  else echo ":COMPLIANT" >> $a
fi


echo -n "10.15 Do not allow cross context requests \(Scored\)">> $a
if  sudo cat $context | grep -i "crosscontext=\"true\""  ; then
  echo ":NOT COMPLIANT" >> $a
  else echo ":COMPLIANT" >> $a
fi


echo -n "10.16 Do not resolve hosts on logging valves \(Scored\)">> $a
if  sudo cat $prefix | grep -i "enablelookups=\"true\""  ; then
  echo ":NOT COMPLIANT" >> $a
  else echo ":COMPLIANT" >> $a
fi


echo -n "10.17 Enable memory leak listener \(Scored\)">> $a
if  sudo cat $prefix | grep -v "<!--" | grep -i "Listener className=\"org.apache.catalina.core.JreMemoryLeakPreventionListener"  ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.18 Setting Security Lifecycle Listener \(Scored\)">> $a
if  sudo cat $prefix | grep -v "<!--" | grep -i securitylistener| grep -i checkedosusers | grep -i minimumumask  ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


echo -n "10.19 Use the logEffectiveWebXml and metadata-complete settings for deploying applications in production \(Scored\)">> $a
cis10191=$(sudo cat $webxml | grep -v "<!--" | grep -i metadata-complete=\"true)
cis10192=$(sudo cat $context | grep -v "<!--" | grep -i logeffectivewebxml=\"true)
if  [[ "cis10191 && cis10192" ]]  ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


echo -n "11.1 Limit HTTP Request Methods \(Scored\)">> $a
if  cat $webxml | grep -v "<!--" | grep -i -A 3 init-param | grep -i -A 2 readonly | grep -i true ; then
  echo ":COMPLIANT" >> $a
  else echo ":NOT COMPLIANT" >> $a
fi


exit