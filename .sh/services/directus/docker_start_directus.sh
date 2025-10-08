#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_start_directus() {
	check_instance_installed

	if [[ "$INSTANCE_INSTALLED" -eq 1 ]]; then
		env_file_load

		if [[ $IS_RUNNING == 0 ]]; then
			docker_compose_runner "up -d"
		else
			ECHO_WARN_YELLOW "Site is already up and running"
		fi

		open_browser
	else
		# Not installed yet
		ECHO_INFO "Instance not installed — starting setup..."
		get_domain_name

		set_custom_args
		check_data_before_continue_callback docker_start_directus

		ECHO_INFO "Setting up Docker containers for [$DOMAIN_NAME]"

		# Delete prev volume if use the same DOMAIN_NAME
		DOCKER_VOLUME_DB="${DOMAIN_NAME}_db_data"
		delete_volume "$DOCKER_VOLUME_DB"
		DOCKER_VOLUME_PG="${DOMAIN_NAME}_pgadmin_data"
		delete_volume "$DOCKER_VOLUME_PG"

		copy_templates_files

		env_file_load "create"
		replace_variables
		env_file_load

		create_network

		ECHO_GREEN "Docker compose file set and container can be built and started"
		ECHO_TEXT "Starting Container"
		docker_compose_runner "up -d --build"

		ECHO_SUCCESS "Containers Started"

		# fix_permissions

		# More actions ?

		# Clone ?

		# Print for user project info
		notice_project_vars
		open_browser

		save_settings "DOMAIN_NAME=$DOMAIN_NAME"
	fi

}
