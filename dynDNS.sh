#!/bin/sh

####### usr/local/bin/dynDNS.sh #################
# This script is in place of a dynamic DNS daemon.
#
# It goes out to the internet to discover the current IP address
# as seen from the internet. i.e. the routers external interface.
# It looks for the previous address in "lastIPaddress".
# If "lastIPaddress" doesn't exist, or its contents don't match,
# notification is sent.

# A "report" is generated each time. It is appended to the log file and
# serves as the message should the address have changed. It is also written
# to the report file overwriting any previously created report that
# might have been created at the time of the last invocation of the script. 

# There is no provision made for house cleaning the log file.

# Out put can be send to /dev/null (if not needed for debugging.)
# 
# Assumptions about environment:
#	there is a cron job (command crontab -l) that hourly runs:
#		/usr/local/bin/dynDNS.sh    # this script
#	the email address used is valid
#	the directory /var/lib/dyndns exists, 
#	the directory /var/log/dyndns exists (to house dynDNS.log)
# Also assumed is that easydns.com continues to offer the utility used
# and that all ownerships and privileges are set appropriately.

# It is expected to be run as a cron job:
# use       $ crontab -e
# to enter the following line:
# """   57 * * * * /usr/local/bin/dynDNS.sh > /dev/null 2>&1 """ or
# """   57 * * * * /usr/local/bin/dynDNS.sh &> /dev/null""" but NOT
# """   57 * * * * /usr/local/bin/dynDNS.sh > /dev/null >&2 """ !!!

# There are no options or arguments.
# 
# It takes advantage of a utility provided by easydns.com which will report
# back the caller's IP address using the wget command. This command brings
# in a file called get_ip.php (but be aware that if the file already exists, 
# it will not be over written. The new one will receive an appended name.)

# Also be aware that occassionaly the utility fails and you will get a
# notification that looks like this:
# """ Sun Jun 3 18:57:01 PDT 2012: plug2 WAN addr has changed 
#     from 76.191.205.213 to Can't connect to MySQL. """
# Make a note of the number and one hour later you'll probably get:
# """ Sun Jun 3 19:57:01 PDT 2012: plug2 WAN addr has changed 
#     from Can't connect to MySQL to 76.191.205.213. """

# It gets the current IP address and if it is different from that found 
# in lastIPaddress, the new address is emailed to the sysadmin who can then
# reconfigure the appropriate DNS server.


# In keeping with my interpretation of the Linux File System Hierarchy 
# document, the executable is to be kept in /usr/local/bin/
# and the supporting files will be in /var/lib/dyndns/

# Plans to refine the program:  (i.e. My ToDo list)
# I'd like to have a configuration file that specifies the directories 
# and files used instead of having them hard coded.
#
# Some things I've discovered:  (Things to keep in mind about Bash.)
# There needs to be a ';' after if conditional(s) and before the 'then'.
# No spaces on either side of an '=' sign.
#
# If I use ADMI="alex@kleider.ca" on plug2, mutt and postfix are smart
# enough to realize that this is the local machine and deliver locally-
# defeating the purpose; so I had to change to "akleider@sonic.net".


ADMIN="alex@kleider.ca"  # Change to an unrelated email address.
HOST=`cat /etc/hostname`
SUBJECT="dynDNS report from ${HOST}"
DIR="/var/lib/dyndns/"
LOG="/var/log/dyndns/dynDNS.log"
DATE=`date`
URL="http://support.easydns.com/utils/get_ip.php"

cd $DIR
printf "%s -- %s\n" "$DATE" "Running dynDNS..."

# The following creates a file get_ip.php that contains the IP address.
# Other fairly useless data is sent to stdout so we make it go away
# by redirecting it to /dev/null.
wget $URL >> /dev/null 2>&1
echo "..comparing previous and current IP addresses.." 
ip1=`cat "get_ip.php"`   
if [ -f lastIPaddress ]; then
    ip2=`cat "lastIPaddress"`
else 
    ip2="UNKNOWN ADDRESS"
fi
echo "New IP addr is ${ip1}; old IP addr is ${ip2}."
if [ $ip1 = $ip2 ]
then
    message="${DATE}: WAN (external) address (${ip1}) has not changed."
    echo $message > report
else
    message="${DATE}: ${HOST} WAN addr has changed \nfrom ${ip2} to ${ip1}."
    echo $message > report
    mutt $ADMIN -s "$SUBJECT" -i report 
    # echo report | mail -s “$SUBJECT”  $ADMIN  # Alternative to mutt.
fi
mv get_ip.php lastIPaddress
echo $message
echo $message >> $LOG

echo "Custom script dynDNS completed successfully." 
echo "                             ----------------------"

exit 0

