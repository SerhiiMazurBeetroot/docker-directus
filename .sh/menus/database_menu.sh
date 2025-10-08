#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

database_menu() {
	check_instance_installed
	check_directus_running

	if [[ "$INSTANCE_INSTALLED" -eq 1 ]]; then
		env_file_load

		if [[ $IS_RUNNING == 0 ]]; then
			ECHO_WARN_RED "Site is not running"

		else
			while true; do
				EMPTY_LINE
				ECHO_CYAN "========== DB menu ========="
				ECHO_YELLOW "0 - Return to the prev menu"
				ECHO_GREEN "1 - Import full DB"
				ECHO_GREEN "2 - Export full DB"
				ECHO_GREEN "3 - Others"

				actions=$(GET_USER_INPUT "select_one_of")

				case $actions in
				0)
					main_menu
					;;
				1)
					database_import_menu
					;;
				2)
					database_export_menu
					;;
				3)
					database_other_menu
					;;
				*)
					ECHO_WARN_RED "Invalid selection. Please try again."
					;;
				esac
			done
		fi

	else
		ECHO_WARN_RED "Invalid selection. Please try again."
	fi

}

database_other_menu() {

	while true; do
		EMPTY_LINE
		ECHO_CYAN "========== DB other ========="
		ECHO_YELLOW "0 - Return to the prev menu"
		ECHO_GREEN "1 - DB info"
		ECHO_GREEN "2 - Roles"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			database_menu
			;;
		1)
			print_connection_info
			;;
		2)
			roles_menu
			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done
}
