#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

# usage array:
# Call: print_list "${ARRAY[@]}"

print_list() {
	OPTION_LIST=("$@")

	for ((i = 0; i < ${#OPTION_LIST[@]}; i++)); do
		index=$((i + 1))
		option="${OPTION_LIST[i]}"
		ECHO_KEY_VALUE "[$index]" "$option"
	done
}
