#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

notice_project_vars() {
	ECHO_INFO "Project variables:"

	ECHO_KEY_VALUE "DOMAIN_NAME:" "$DOMAIN_NAME"

	for arg in "${ARGS[@]}"; do
		value="${!arg}"

		if [[ -n "$value" ]]; then
			ECHO_KEY_VALUE "$arg:" "$value"
		fi
	done

	ECHO_YELLOW "You can find this info in the file ["$ENV_FILE"]"
	EMPTY_LINE
}

open_browser() {
	if command -v google-chrome &>/dev/null; then
		google-chrome "http://localhost:$APP_PORT" || true
	else
		ECHO_TEXT "Google Chrome is not installed. Skipping opening URL."
	fi
}
