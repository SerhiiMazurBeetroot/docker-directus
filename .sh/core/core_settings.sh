#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

set_env_mode() {
	if [[ ! -f "$FILE_SETTINGS" ]]; then
		touch "$FILE_SETTINGS"
	fi

	if [[ ! -f "$FILE_LOGS" ]]; then
		touch "$FILE_LOGS"
	fi

	save_settings "CORE_VERSION=1.0.0"

	if grep -q '^ENV_MODE=' "$FILE_SETTINGS"; then
		ENV_MODE=$(grep '^ENV_MODE=' "$FILE_SETTINGS" | cut -d'=' -f2)
	else
		ENV_MODE=""
	fi

	# ─────────────────────────────────────────────
	# Case 1: No ENV_MODE yet
	# ─────────────────────────────────────────────

	if [[ -z "$ENV_MODE" ]]; then
		ECHO_CYAN "========== Select ENV_MODE ========="
		ECHO_GREEN "1 - Production"
		ECHO_GREEN "2 - Local [default]"
		local choice=$(GET_USER_INPUT "select_one_of")

		case "$choice" in
		1)
			ENV_MODE="prod"
			SCRIPT_MODE="psql"
			;;
		2 | *)
			ENV_MODE="local"
			SCRIPT_MODE="docker"

			;;
		esac

		save_settings "ENV_MODE=$ENV_MODE"

	# ─────────────────────────────────────────────
	# Case 2: auto-detect SCRIPT_MODE
	# ─────────────────────────────────────────────
	else
		case "$ENV_MODE" in
		prod) SCRIPT_MODE="psql" ;;
		local) SCRIPT_MODE="docker" ;;
		*)
			ECHO_WARN_RED "Unknown ENV_MODE in $FILE_SETTINGS, defaulting to local"
			ENV_MODE="local"
			SCRIPT_MODE="docker"
			save_settings "ENV_MODE=$ENV_MODE"
			;;
		esac

	fi

}

save_settings() {
	local settings=("$@")

	# Read existing settings from file into separate arrays
	local existing_keys=()
	local existing_values=()

	if [[ -f "$FILE_SETTINGS" ]]; then
		while IFS='=' read -r existing_key existing_value; do
			existing_keys+=("$existing_key")
			existing_values+=("$existing_value")
		done <"$FILE_SETTINGS"
	fi

	# Update existing settings and add new settings to the separate arrays
	for setting in "${settings[@]}"; do
		key="${setting%=*}"
		value="${setting#*=}"

		# Check if the key already exists in the array
		index=""
		for ((i = 0; i < ${#existing_keys[@]}; i++)); do
			if [[ "${existing_keys[i]}" == "$key" ]]; then
				index=$i
				break
			fi
		done

		if [[ -n $index ]]; then
			existing_values[index]="$value"
		else
			existing_keys+=("$key")
			existing_values+=("$value")
		fi
	done

	# Save the updated settings to the file
	for ((i = 0; i < ${#existing_keys[@]}; i++)); do
		echo "${existing_keys[i]}=${existing_values[i]}"
	done >"$FILE_SETTINGS"
}
