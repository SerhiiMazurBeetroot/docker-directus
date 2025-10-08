#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

roles_menu() {

	while true; do
		EMPTY_LINE
		ECHO_CYAN "========== Roles menu ========="
		ECHO_YELLOW "0 - Return to the prev menu"
		ECHO_GREEN "1 - Create role"
		ECHO_GREEN "2 - Grant to role"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			database_menu
			;;
		1)
			read -rp "Enter role name: " role
			if [[ -n "$role" ]]; then
				env_file_load
				create_role_if_not_exists "$role"
			fi
			;;
		2)
			case "$ENV_MODE" in
			"local")
				ECHO_WARN_RED "Only PROD is supported for this action."
				;;
			"prod")
				read -rp "Enter role name: " role
				if [[ -n "$role" ]]; then
					env_file_load
					grant_to_role "$role"
				fi
				;;
			esac

			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done
}

create_role_if_not_exists() {
	local role=$1

	if ! check_role_exists "$role"; then
		role_create "$role"
	else
		ECHO_TEXT "Role [$role] already exists, skipping creation."
	fi
}

grant_to_role() {
	local role=$1
	if check_role_exists "$role"; then
		read -rp "Enter grant to role: " grant_role
		if check_role_exists "$grant_role"; then
			local grant_sql="GRANT \"$role\" TO \"$grant_role\";"
			exec_psql_command "$grant_sql" "postgres"

			if [[ $? -ne 0 ]]; then
				ECHO_TEXT "Failed to grant role [$role] to $grant_role"
				exit 1
			else
				ECHO_TEXT "Successfully granted role [$role] to $grant_role"
			fi
		else
			ECHO_WARN_RED "Grant role name cannot be empty or already exists."
		fi
	else
		ECHO_WARN_RED "Role [$role] doesn't exist, skipping"
	fi
}

check_role_exists() {
	local role=$1

	local role_sql="SELECT 1 FROM pg_roles WHERE rolname='$role';"
	exec_psql_command "$role_sql" "postgres" "-tA" | grep -q 1
}

role_create() {
	local role=$1

	local role_sql="CREATE ROLE \"$role\" WITH LOGIN;"
	exec_psql_command "$role_sql" "postgres"

	if [[ $? -ne 0 ]]; then
		ECHO_TEXT "Failed to create role [$role]"
		exit 1
	else
		ECHO_TEXT "Role [$role] created successfully."
	fi
}
