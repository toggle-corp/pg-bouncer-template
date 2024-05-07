#!/bin/bash

export $(cat .env | grep '^CONNECT_' | xargs)

psql "sslmode=verify-full password=$CONNECT_PASSWORD user=$CONNECT_USER host=$CONNECT_HOST port=$CONNECT_PORT sslcert=$CONNECT_SSLCERT sslkey=$CONNECT_SSLKEY sslrootcert=$CONNECT_SSLROOTCERT dbname=$CONNECT_DBNAME"


# psql "sslmode=verify-ca sslrootcert=$CONNECT_SSLROOTCERT password=$CONNECT_PASSWORD user=$CONNECT_USER host=$CONNECT_HOST port=$CONNECT_PORT dbname=$CONNECT_DBNAME"
