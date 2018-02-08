#!/bin/bash

passfile=./pass.sec

export PASS=$(openssl enc -aes-256-cbc -d -in $passfile)
