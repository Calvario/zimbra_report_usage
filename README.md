# License

Copyright (C) 2015 Steve Calvário

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

LICENSE.txt contains a copy of the full GPLv3 licensing conditions.

# Introduction

This script will make a report of :
- Zimbra version
- Hostname
- Local IP address
- Server date time
- Server uptime
- Zimbra mailbox usage, quota and status for all accounts
- Total of Zimbra mailbox usage and quota usage
- Disk usage
- Backup folder size

It will send you a mail notification.

# Notes

- You need to have Zimbra Collaboration Network Edition to use this script
- The mail notification will use the local zimbra server to send the mail
- Do not forget to change the values in script !
- Use , to have more than one recipient. Ex : name@domain.tld,name2@domain.tld

# Tested in

- CentOS 7.1.1503 x64, Zimbra Collaboration Network Edition 8.6.0

# How to install

Create a scripts folder in Zimbra
```
mkdir /opt/zimbra/scripts
```
Copy the script downloaded in this folder.
Change the owner and the rights of the script file.
```
chown zimbra:zimbra /opt/zimbra/scripts -R
chmod 755 /opt/zimbra/scripts/zimbra_report_usage.sh
```
Create a cron job for the script.
In this example, the script will run every Friday at 7:45
```
cat <<EOT > /etc/cron.d/zimbra_report_usage
45 7 * * 5 zimbra /opt/zimbra/scripts/zimbra_report_usage.sh > /dev/null 2>&1
EOT

```
