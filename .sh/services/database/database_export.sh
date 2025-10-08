#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

database_export_menu() {
	EMPTY_LINE
	ECHO_CYAN "======== Export DB ======="

	ECHO_YELLOW "Export [$ENV_MODE] DB?"
	ECHO_GREEN "1 - Yes"
	ECHO_GREEN "2 - No"

	local choice=$(GET_USER_INPUT "select_one_of")

	if [[ "$choice" = "1" ]]; then
		database_export "full" "$DATABASE_BACKUP_DIR"
	fi
}

database_export() {
	env_file_load

	EMPTY_LINE
	ECHO_TEXT "Running fn [database_export] for [$ENV_MODE]" "fn"

	local export_type=${1:-"full"}
	local database_dir=${2:-$DATABASE_BACKUP_DIR}

	# Save old files to "DATABASE_BACKUP_DIR" before deleting
	for files in $database_dir/*.dump; do
		if [ -e "$files" ]; then
			ECHO_TEXT "There are old files to delete [$database_dir]"
			rm -f $database_dir/*.dump
			break
		fi
	done

	if [ "$DB_NAME" ]; then
		get_timestamp

		#DUMP_FILE
		DUMP_FILE=$export_type-$DB_NAME-$TIMESTAMP.dump
		file=$database_dir/$DUMP_FILE

		# create_dump
		case "$ENV_MODE" in
		"local")
			database_export_docker
			;;
		"prod")
			database_export_psql
			;;
		esac

		EMPTY_LINE
		ECHO_SUCCESS "DB [$DB_NAME] saved to: [$file]"

	fi

}

database_export_docker() {
	check_db_container

	if [ "$DB_CONTAINER_EXISTS" ]; then
		ECHO_GREEN "Docker DB container exists"

		case "$export_type" in
		0)
			exit
			;;
		"full")
			# Full
			docker exec -i "$DB_HOST" pg_dump -U "$DB_USER" -d "$DB_NAME" -F c >"$file"
			;;
		"predefined")
			# predefined tables
			local tables_string=$(printf " -t %s" "${EXPORT_TABLES[@]}")

			docker exec -i "$DB_HOST" \
				pg_dump -U "$DB_USER" -d "$DB_NAME" \
				--data-only --disable-triggers \
				$tables_string \
				-F c >"$file"
			;;
		esac
	else
		ECHO_ERROR "DB container is not running"
	fi
}

database_export_psql() {
	ECHO_TEXT "Running fn [database_export_psql] for [$ENV_MODE]"

	case "$export_type" in
	0)
		exit
		;;
	1)
		# Full
		PGPASSWORD="$DB_PASSWORD" pg_dump \
			-h "$DB_HOST" \
			-U "$DB_USER" -d "$DB_NAME" \
			-F c >"$file"
		;;
	2)
		# predefined tables
		local tables_string=$(printf " -t %s" "${EXPORT_TABLES[@]}")

		PGPASSWORD="$DB_PASSWORD" pg_dump \
			-h "$DB_HOST" \
			-U "$DB_USER" -d "$DB_NAME" \
			--data-only --disable-triggers \
			$tables_string \
			-F c >"$file"
		;;
	esac
}
