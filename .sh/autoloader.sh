#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

source_files_in() {
	local dir="$1"

	if [[ -r "$dir" && -x "$dir" ]]; then
		for file in "$dir"/*; do
			if [[ -f "$file" && -r "$file" ]]; then
				. "$file"
			elif [[ -d "$file" ]]; then
				source_files_in "$file"
			fi
		done
	fi
}

source_files_in "./.sh/utils"
source_files_in "./.sh/core"
source_files_in "./.sh/menus"
source_files_in "./.sh/services"
