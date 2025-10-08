#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

database_export_tables() {
	ECHO_TEXT "Running fn [database_export_tables] for [$ENV_MODE]"
	EMPTY_LINE

	local database_dir=${2:-$DATABASE_BACKUP_DIR}

	get_timestamp

	# delete old files
	for files in $database_dir/*.dump; do
		if [ -e "$files" ]; then
			ECHO_TEXT "There are old files to delete [$database_dir]"
			rm -f $database_dir/*.dump
			break
		fi
	done

	#DUMP_FILE
	DUMP_FILE=dump-$DB_NAME-$TIMESTAMP.dump
	file=$database_dir/$DUMP_FILE

	ECHO_CYAN "Exporting data to: [$file]"
	EMPTY_LINE
	local tables_string=$(printf " -t %s" "${EXPORT_TABLES[@]}")

	case "$ENV_MODE" in
	"local")
		docker exec -i "$DB_HOST" \
			pg_dump -U "$DB_USER" -d "$DB_NAME" \
			--data-only --disable-triggers \
			--no-owner \
			$tables_string \
			-F c >"$file"
		;;
	"prod")
		PGPASSWORD="$DB_PASSWORD" pg_dump \
			-h "$DB_HOST" \
			-U "$DB_USER" -d "$DB_NAME" \
			--data-only --disable-triggers \
			--no-owner \
			$tables_string \
			-F c >"$file"
		;;
	esac

	EMPTY_LINE
}
