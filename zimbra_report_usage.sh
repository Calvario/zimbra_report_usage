#!/usr/bin/env bash

# ----------------------------------------------------------------------------------------
# Title		: zimbra_report_usage.sh
# Author	: Steve Calvário
# Date		: 2015-09-16
# Version	: 1.5
# Github	: https://github.com/Calvario/zimbra_report_usage/
# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# Copyright (c) 2015 Steve Calvrio <https://github.com/Calvario/>
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.  Please see LICENSE.txt at the top level of
# the source code distribution for details.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# You must edit the following variables to match with your production environment
# ----------------------------------------------------------------------------------------

server_network_card='ens999'

mail_subject="Report usage of server.domain.tld"
mail_send_from="\"SenderName\" <name@domain.tld>"
mail_send_to='name@domain.tld'

zimbra_sendmail='/opt/zimbra/postfix/sbin/sendmail'

script_log='zimbra_report_usage.log'
script_lock='zimbra_report_usage.lock'

PATH=/opt/zimbra/bin:/usr/sbin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin

# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# !!! Do not change the lines below !!!
# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# Check that the environment is correct
# ----------------------------------------------------------------------------------------

if [ $(whoami) != "zimbra" ]
then
	error="This script must be executed with the zimbra account"
	echo $error
	echo "$(date '+%Y-%m-%d %H:%M:%S') - Error : $error" >> $script_log
	exit 1
elif ! type zmcontrol > /dev/null
then
	error="Apparently Zimbra is not installed"
	echo $error
	echo "$(date '+%Y-%m-%d %H:%M:%S') - Error : $error" >> $script_log
	exit 1
elif ! type flock > /dev/null
then
	error="flock is required to use this script, please install it."
	echo $error
	
	echo "$(date '+%Y-%m-%d %H:%M:%S') - Error : $error" >> $script_log
	exit 1
fi

# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# Create lock file 
# ----------------------------------------------------------------------------------------

set -e

exec 200>$script_lock
flock -n 200 || exit 1

script_pid=$$
echo $script_pid 1>&200

# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# Variable initialization
# ----------------------------------------------------------------------------------------

server_name=$(hostname)
server_date=$(date '+%Y-%m-%d %H:%M:%S')
server_uptime=$(uptime | awk -F '(  |,)' '{print $2}')
server_network_ip=$(ifconfig $server_network_card | grep 'inet' | cut -d: -f2 | awk '{ print $2}')

mail_mime_version='1.0'
mail_content_type='text/html'

zimbra_version=$(zmcontrol -v)
zimbra_backup_folder=$(zmprov gacf zimbraBackupTarget | cut -d: -f2)
zimbra_backup_folder_size=$(du -sh $zimbra_backup_folder)
zimbra_mailbox_usage_total="$(zmprov gqu $server_name | awk '{ sum += ($3 / 1073741824) } END { if (NR > 0) print sum}')"
zimbra_mailbox_quota_total="$(zmprov gqu $server_name | awk '{ sum += ($2 / 1073741824) } END { if (NR > 0) print sum}')"

# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# Functions
# ----------------------------------------------------------------------------------------

func_server_disk() {

	df -h | awk '{if (NR!=1) {print $6" "$2" "$3" "$4" "$5}}' | while read server_disk_line
	do
		server_disk_name=$(echo $server_disk_line | cut -f1 -d " ")
		server_disk_size=$(echo $server_disk_line | cut -f2 -d " ")
		server_disk_usage=$(echo $server_disk_line | cut -f3 -d " ")
		server_disk_available=$(echo $server_disk_line | cut -f4 -d " ")
		server_disk_usage_percent=$(echo $server_disk_line | cut -f5 -d " ")
		
		echo "
			<tr>
				<td>$server_disk_name</td>
				<td>$server_disk_size</td>
				<td>$server_disk_usage</td>
				<td>$server_disk_available</td>
				<td>$server_disk_usage_percent</td>
			</tr>"
	done
}

func_zimbra_mailbox_list() {

	zmprov gqu $1 | awk {'print $1" "$3" "$2'} | sort -k2rn | while read zimbra_mailbox_line
	do
		zimbra_mailbox_user=$(echo $zimbra_mailbox_line | cut -f1 -d " ")
		zimbra_mailbox_usage=$(echo $zimbra_mailbox_line | cut -f2 -d " " | awk '{printf "%.2f", $1 / 1073741824}')
		zimbra_mailbox_quota=$(echo $zimbra_mailbox_line | cut -f3 -d " " | awk '{printf "%.2f", $1 / 1073741824}')
		zimbra_mailbox_status=$(zmprov ga $zimbra_mailbox_user | grep  ^zimbraAccountStatus | cut -f2 -d " ")

		echo "
			<tr>
				<td>$zimbra_mailbox_user</td>
				<td>$zimbra_mailbox_usage G</td>
				<td>$zimbra_mailbox_quota G</td>
				<td>$zimbra_mailbox_status</td>
			</tr>"
	done
}

# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# Formatting the message and send the notification mail
# ----------------------------------------------------------------------------------------

mail_message="
From: $mail_send_from
\nTo: $mail_send_to
\nMIME-Version: $mail_mime_version
\nContent-Type: $mail_content_type
\nSubject: $mail_subject
\n\n

<!DOCTYPE HTML>
<html>
<head>
	<title>$mail_subject</title>
	<meta charset=\"UTF-8\">
	<style>
		th { text-align: left; }
	</style>
</head>
<body>
	<h1>$mail_subject</h1>
	
	<h2>Information</h2>
	<p>Zimbra version : $zimbra_version<br/>
	<br/>
	Server hostname : $server_name<br/>
	Server IP address : $server_network_ip<br/>
	Server date : $server_date<br/>
	Server uptime : $server_uptime</p>
	
	<h2>List of mailboxes</h2>
	<table>
		<tr>
			<th>Mail address</th>
			<th>Mailbox size</th>
			<th>Mailbox quota</th>
			<th>Account status</th>
		</tr>
		$(func_zimbra_mailbox_list $server_name)
		<tr>
			<td></td>
			<td></td>
			<td></td>
			<td></td>
		</tr>
		<tr>
			<td><b>Total</b></td>
			<td><b>$zimbra_mailbox_usage_total G</b></td>
			<td><b>$zimbra_mailbox_quota_total G</b></td>
			<td></td>
		</tr>
	</table>
	
	<h2>Disk usage</h2>
	<p><b>Size of the backup folder</b> : $zimbra_backup_folder_size</p>
	<table>
		<tr>
			<th>Mountpoint</th>
			<th>Total size</th>
			<th>Use</th>
			<th>Free space</th>
			<th>Use in %</th>
		</tr>
		$(func_server_disk)
	</table>
</body>
</html>
"

echo -e $mail_message | $zimbra_sendmail $mail_send_to

# ----------------------------------------------------------------------------------------
