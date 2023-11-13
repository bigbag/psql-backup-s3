#! /bin/bash
# PSQL Database Backup to AWS S3

echo "Starting PSQL Database Backup..."

# Ensure all required environment variables are present
if [ -z "$DB_PASSWORD" ] || \
    [ -z "$DB_USER" ] || \
    [ -z "$DB_SERVICE_NAME" ] || \
    [ -z "$DB_TABLES" ] || \
    [ -z "$DB_NAME" ] || \
    [ -z "$AWS_ACCESS_KEY_ID" ] || \
    [ -z "$AWS_SECRET_ACCESS_KEY" ] || \
    [ -z "$AWS_DEFAULT_REGION" ] || \
    [ -z "$S3_BUCKET" ]; then
    >&2 echo 'Required variable unset, database backup failed'
    exit 1
fi

DB_PORT="${DB_PORT:=5432}"

# Make sure local bin in path
export PATH=/usr/local/bin:$PATH


# Create backup params
backup_dir=$(mktemp -d)
backup_name=$DB_NAME'_'$(date +%Y%m%d'_'%H%M).sql
backup_path="$backup_dir/${backup_name}"
final_backup_path="$backup_dir/${backup_name}.bz2"

dump_db(){
    DUMP_DB_CMD='PGPASSWORD='$DB_PASSWORD' pg_dump --inserts -d "'$DB_NAME'" -U "'$DB_USER'" -h "'$DB_SERVICE_NAME'" -p "'$DB_PORT'"'

    DB_TABLES_ARRAY=(${DB_TABLES//;/ })
    TABLES_STRING=""
    for i in "${!DB_TABLES_ARRAY[@]}"
    do
        TABLES_STRING="$TABLES_STRING -t ${DB_TABLES_ARRAY[i]}"
    done

    DUMP_DB_CMD="$DUMP_DB_CMD $TABLES_STRING"

    echo 'Create, compress the backup ...'
    eval $DUMP_DB_CMD > $backup_path

    backup_size=$(stat --format=%s "$backup_path")
    if [[ $backup_size -eq 0 ]]; then
        echo 'Backup file is empty'
        exit 1
    fi
    bzip2 -9 -f $backup_path
}

push_backup_to_s3(){
    # Check backup created
    if [ ! -e "$final_backup_path" ]; then
        echo 'Backup file not found'
        exit 1
    fi

    echo 'Push backup to S3 ...'
    aws s3 cp "$final_backup_path" "s3://$S3_BUCKET"
    status=$?

    # Remove tmp backup path
    rm -rf "$backup_dir"

    # Indicate if backup was successful
    if [ $status -eq 0 ]; then
        echo "PSQL database backup: '$backup_name.bz2' completed to '$S3_BUCKET'"
    else
        echo "PSQL database backup: '$backup_name.bz2' failed"
        exit 1
    fi
}

dump_db
push_backup_to_s3
