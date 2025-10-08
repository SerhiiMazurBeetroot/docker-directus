#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

check_data_before_continue_callback() {
	EMPTY_LINE
	ECHO_INFO "Check everything before proceeding:"

	while true; do
		notice_project_vars

		yn=$(GET_USER_INPUT "question" "Is that correct?" "y")

		case $yn in
		[Yy]*)
			break
			;;
		[Nn]*)
			ECHO_ERROR "Enter correct information"
			unset_variables

			# Run next function again
			($1)
			break
			;;

		*) echo "Please answer [y/n]" ;;
		esac
	done
}

copy_templates_files() {
	local templates_dir="./.sh/templates"

	if [ -d "$templates_dir" ]; then
		if [ "$(ls -A "$templates_dir")" ]; then
			shopt -s dotglob # include hidden files in glob
			cp -r "$templates_dir"/* ./
			shopt -u dotglob # disable after use
			ECHO_SUCCESS "Template files copied successfully."
		else
			ECHO_WARN "No templates found in $templates_dir"
		fi
	else
		ECHO_ERROR "Please check your templates directory: $templates_dir"
	fi
}

get_directus_version() {
	# shellcheck disable=SC2207
	LIST=($(curl -s 'https://api.github.com/repos/directus/directus/tags' | grep -oP '"name": "\Kv[0-9]+\.[0-9]+\.[0-9]+' | head -n 3 | tr -d v))

	if [ -z "$DIRECTUS_VERSION" ]; then
		if [[ $QUESTION == "default" ]]; then
			DIRECTUS_VERSION="${LIST[1]}"
		else
			DIRECTUS_VERSION="${LIST[1]}"
			ECHO_ENTER "Enter DIRECTUS_VERSION [default '$DIRECTUS_VERSION']"

			print_list "${LIST[@]}"

			choice=$(GET_USER_INPUT "select_one_of")
			choice=${choice%.*}

			if [ -z "$choice" ]; then
				choice=-1
				DIRECTUS_VERSION="${LIST[1]}"
			else
				if (("$choice" > 0 && "$choice" <= ${#LIST[@]})); then
					DIRECTUS_VERSION="${LIST[$(($choice - 1))]}"
				else
					ECHO_WARN_RED "Invalid choice or version. Using default version: $DIRECTUS_VERSION"
					ECHO_GREEN "Set default version: $DIRECTUS_VERSION"
					EMPTY_LINE
				fi
			fi
		fi
	fi

}

get_compose_project_name() {
	if [ -n "$DOMAIN_NAME" ]; then
		COMPOSE_PROJECT_NAME=$(echo "$DOMAIN_NAME"-directus | sed "s/[^a-zA-Z0-9_\-]/_/g; s/^-//; s/-$/_/; s/-/_/g; s/[^a-zA-Z0-9_\-]//g; s/^$/none/")
	fi
}

randpassword() {
	local length=${1:-20}

	LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= </dev/urandom | head -c "$length" || true
}

generate_random_string() {
	local length="${1:-32}"

	string=$(LC_CTYPE=C tr -dc 'A-Za-z0-9_' </dev/urandom | head -c "$length" || true)

	echo "$string"
}

check_instance_installed() {
	INSTANCE_INSTALLED=0

	# Detect installation based on key files
	if [[ -f ".env.local" || -f ".env" ]]; then
		INSTANCE_INSTALLED=1
	fi
}

create_network() {
	if [ ! "$(docker network ls | grep "$DOMAIN_NAME"_directus)" ]; then
		docker network create "$DOMAIN_NAME"_directus
	fi
}

check_directus_running() {
	IS_RUNNING=0

	DOMAIN_NAME=$(awk -F '=' '/^DOMAIN_NAME=/{print $2; exit}' $FILE_SETTINGS)

	# Check for Docker containers (running or stopped)
	if docker ps --format '{{.Names}}' | grep -q "^${DOMAIN_NAME}-directus$"; then
		IS_RUNNING=1
	fi

	if docker ps --format '{{.Names}}' | grep -q "^${DOMAIN_NAME}-db$"; then
		IS_RUNNING=1
	fi

}

# Function to safely delete a volume
delete_volume() {
	local volume_name="$1"

	# find exact match
	matches=$(docker volume ls --format '{{.Name}}' | grep -E "(^|_|-)$volume_name($)" || true)

	if [ -n "$matches" ]; then
		EMPTY_LINE
		for v in $matches; do
			docker volume rm "$v"
			ECHO_YELLOW "Deleted Docker volume: $v"
		done
	else
		ECHO_ERROR "Docker volume does not exist: $volume_name"
	fi
}
