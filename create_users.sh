#!/bin/bash
logfile='/var/log/user_management.log'
passwdstore='/var/secure/user_passwords.csv'
function create_users(){
	local file="$1"
	while read -r line; do
		IFS=';' read -r -a USER <<< "$line"
		if grep -q "${USER[0]}" /etc/passwd; then
			echo "User ${USER[0]} already exists. Skipping." >> "$logfile"
			continue
		else
			useradd -m "${USER[0]}"
			PASSWORD=$(openssl rand -base64 12)
			echo "${USER[0]}:$PASSWORD" | chpasswd
			echo "User ${USER[0]} has been created with password: $PASSWORD" >> "$logfile"
			echo "${USER[0]},$PASSWORD" >> "$passwdstore"

		fi

		IFS=',' read -r -a groups <<< "${USER[1]}"
		for group in "${groups[@]}"; do
  			GROUP=group | xargs
			if id -nG "${USER[0]}" | grep -qw "$GROUP"; then
				echo "User ${USER[0]} is already in group $GROUP. Skipping." >> "$logfile"
				continue
			elif grep -qw "$GROUP" /etc/group; then
				usermod -a -G "$GROUP" "${USER[0]}"
				echo "User ${USER[0]} added to existing group $GROUP." >> "$logfile"
			else
				groupadd "$GROUP"
				usermod -a -G "$GROUP" "${USER[0]}"
				echo "Group $GROUP created and user ${USER[0]} added to it." >> "$logfile"
			fi
		done

	done < "$file"
 	chmod 400 "$passwdstore"
}

create_users "$1"
