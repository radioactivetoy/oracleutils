#!/bin/bash
# Execute as . ./setpass.sh to set the password as environment variable

passfile=./pass.sec

export PASS=$(openssl enc -aes-256-cbc -d -in $passfile)
