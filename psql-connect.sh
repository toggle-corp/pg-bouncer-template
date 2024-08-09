#!/bin/bash

if [ -z "$1" ]; then
    echo "No env path supplied"
    exit 1
else
    echo "Using env file: $1"
    set -o allexport
    source "$1" set
    set +o allexport
fi

psql "sslmode=verify-full password=$CONNECT_PASSWORD user=$CONNECT_USER host=$CONNECT_HOST port=$CONNECT_PORT sslcert=$CONNECT_SSLCERT sslkey=$CONNECT_SSLKEY sslrootcert=$CONNECT_SSLROOTCERT dbname=$CONNECT_DBNAME"


# psql "sslmode=verify-ca sslrootcert=$CONNECT_SSLROOTCERT password=$CONNECT_PASSWORD user=$CONNECT_USER host=$CONNECT_HOST port=$CONNECT_PORT dbname=$CONNECT_DBNAME"
