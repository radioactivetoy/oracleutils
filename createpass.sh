#!/bin/bash
# Create an encrypted file with the password

if [ $# -ne 1 ]; then
	echo "createpass.sh password"
	exit 1
fi

echo $1 | openssl enc -aes-256-cbc -out pass.sec
