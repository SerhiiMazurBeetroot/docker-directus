#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

aws_cli_install() {
	# Install AWS CLI if not present
	if ! command -v aws >/dev/null 2>&1; then
		yum install -y aws-cli
	fi
}
