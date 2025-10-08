#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

get_project_args() {
	ARGS=(
		"DB_NAME"
		"DB_USER"
		"DB_PASSWORD"
		"ADMIN_EMAIL"
		"ADMIN_PASSWORD"
		"DIRECTUS_VERSION"
	)
}

set_custom_args() {
	get_project_args
	get_compose_project_name

	local skip_user_input=false

	for arg in "${ARGS[@]}"; do
		case $arg in
		'DB_NAME')
			default_value="directus"
			;;
		'DB_USER')
			default_value="directus"
			;;
		'DB_PASSWORD')
			DB_PASSWORD=$(randpassword 10)
			default_value="directus"
			;;
		'ADMIN_EMAIL')
			default_value="admin@example.com"
			;;
		'ADMIN_PASSWORD')
			ADMIN_PASSWORD=$(randpassword 10)
			default_value="1"
			;;
		'NODE_VERSION')
			get_nodejs_version
			skip_user_input=true
			;;
		'DIRECTUS_VERSION')
			get_directus_version
			skip_user_input=true
			;;
		*)
			echo "Unsupported argument: $arg"
			;;
		esac

		if [[ "$skip_user_input" != true ]]; then
			# Print user choice

			read -rp "$(ECHO_ENTER "Enter $arg [default '$default_value']")" user_input
			if [[ -n "$user_input" ]]; then
				eval "$arg=\"$user_input\""
			else
				eval "$arg=\"$default_value\""
			fi

			skip_user_input=false
		fi

	done
}
