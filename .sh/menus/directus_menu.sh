#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

directus_menu() {
	check_directus_running

	while true; do
		EMPTY_LINE
		ECHO_CYAN "========== Directus menu ========="
		ECHO_YELLOW "0 - Return to the prev menu"
		ECHO_GREEN "1 - Stop"
		ECHO_GREEN "2 - Start"
		ECHO_GREEN "3 - Restart"
		ECHO_GREEN "4 - Rebuild"
		ECHO_GREEN "5 - Get IP"

		local actions=$(GET_USER_INPUT "select_one_of")

		if [ ! "$(docker network ls | grep docker-directus)" ]; then
			docker network create docker-directus
		fi

		case $actions in
		0)
			main_menu
			;;
		1)
			if [[ $IS_RUNNING == 1 ]]; then
				docker_compose_runner "down --remove-orphans"
			else
				ECHO_WARN_YELLOW "Site is not running"
			fi
			;;
		2)
			docker_start_directus
			;;
		3)
			if [[ $IS_RUNNING == 1 ]]; then
				docker_compose_runner "down --remove-orphans"
				docker_compose_runner "up -d"
			else
				ECHO_WARN_YELLOW "Site is not running"
			fi
			;;
		4)
			docker_compose_runner "up -d --force-recreate --no-deps --build"
			;;
		5)
			if [[ $IS_RUNNING == 1 ]]; then
				get_docker_ip "$DOMAIN_NAME-directus"
				ECHO_KEY_VALUE "PUBLIC_IP" "$DOCKER_IP:8055"
			else
				ECHO_WARN_YELLOW "Site is not running"
			fi
			;;
		esac
	done
}
