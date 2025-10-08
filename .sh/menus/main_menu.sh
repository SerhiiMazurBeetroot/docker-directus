#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

main_menu() {

	ECHO_ENTER "Use numbers to select"
	EMPTY_LINE

	healthcheck
	set_env_mode
	detect_os

	case "$ENV_MODE" in
	"prod")
		main_menu_prod
		;;
	"local")
		main_menu_local
		;;
	esac

}

main_menu_local() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "======== $ENV_MODE ======="
		ECHO_YELLOW "0 - Exit and do nothing"
		ECHO_GREEN "1 - Directus"
		ECHO_GREEN "2 - Database"

		choice=$(GET_USER_INPUT "select_one_of")

		case "$choice" in
		0)
			exit
			;;
		1)
			directus_menu
			;;
		2)
			database_menu
			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done
}

main_menu_prod() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "======== $ENV_MODE ======="
		ECHO_YELLOW "0 - Exit and do nothing"
		ECHO_GREEN "1 - Directus"
		ECHO_GREEN "2 - Database"

		choice=$(GET_USER_INPUT "select_one_of")

		case "$choice" in
		0)
			exit
			;;
		1)
			directus_menu
			;;
		2)
			database_menu
			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done
}
