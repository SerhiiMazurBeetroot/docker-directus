#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

healthcheck() {
	get_bash_version
}

get_bash_version() {
	# Check if Bash version is 4 or higher
	if [[ "${BASH_VERSINFO:-0}" -lt 4 ]]; then
		ECHO_ERROR "Please install Bash 4 or higher."
		ECHO_KEY_VALUE "- bash: " "$BASH_VERSION"

		exit 1
	fi
}

env_file_load() {
	local ACTION=$1

	ENV_FILE=".env"
	local ENV_EXAMPLE=".env.example"

	# Switch for local mode
	if [[ "$ENV_MODE" == "local" ]]; then
		ENV_FILE=".env.local"
	fi

	# Load existing env file
	if [[ -z "$ACTION" && -f "$ENV_FILE" ]]; then
		source "$PWD/$ENV_FILE"

	elif [[ "$ACTION" == "create" && -f "$ENV_EXAMPLE" ]]; then
		cp "$PWD/$ENV_EXAMPLE" "$PWD/$ENV_FILE"
		ECHO_SUCCESS "Created $ENV_FILE from $ENV_EXAMPLE"
	fi

	export DB_NAME=$DB_DATABASE

}

get_domain_name() {
	if [ -z "$DOMAIN_NAME" ]; then
		ECHO_ENTER "Enter Domain Name without subdomain:"
		read -rp 'Domain: ' DOMAIN_NAME

		while [ -z "$DOMAIN_NAME" ]; do
			read -rp "Please fill in the Domain: " DOMAIN_NAME
		done

		# Remove non printing chars from DOMAIN_NAME
		DOMAIN_NAME=$(echo $DOMAIN_NAME | tr -dc '[[:print:]]' | tr -d ' ' | tr -d '[A' | tr -d '[C' | tr -d '[B' | tr -d '[D')

		# Replace "_" to "-"
		DOMAIN_NAME=$(echo $DOMAIN_NAME | sed 's/_/-/g')

		# Remove subdomain
		DOMAIN_NAME=$(echo ${DOMAIN_NAME} | cut -d . -f 1)
	fi

	export DOMAIN_NAME
}

get_timestamp() {
	export TIMESTAMP=$(date +"%Y_%m_%d_%H%M%S")
}

detect_os() {
	UNAME=$(command -v uname)

	case $("${UNAME}" | tr '[:upper:]' '[:lower:]') in
	linux*)
		OSTYPE='linux'
		;;
	darwin*)
		OSTYPE='darwin'
		;;
	msys* | cygwin* | mingw*)
		# or possible 'bash on windows'
		OSTYPE='windows'
		;;
	nt | win*)
		OSTYPE='windows'
		;;
	*)
		OSTYPE='unknown'
		;;
	esac
	export $OSTYPE
}
