#!/usr/bin/bash
# Connect to a database, if more than one match a menu is shown to select connection
# connect.sh database

passfile=./pass.sec

trap ctrl_c INT

function ctrl_c() {
       chtitle "Cygwin"
	exit 1 
}                                                                             

if [ $# -ne 1 ]; then
	echo "Usage: connect.sh db"
	exit 1 
fi 

findtns(){                                                                   
    awk -F"[ =]" '/DESCRIPTION/ { print X }{ X=$1 }' $tnsfile | grep -i $1;     
}                                                                            
                                           
chtitle()
{
  cmd /c RenameTab "$1"
}

connect()
{
 	echo "Connecting to $1"
	chtitle $1	 
	$sqlclexec "$USER/$PASS@$1"
	chtitle "Cygwin"
}

if [ -v $PASS ]; then
        PASS=$(openssl enc -aes-256-cbc -d -in $passfile)
fi


connections=$(findtns $1)

if [ $(echo -e "$connections" | wc -l) -gt 1 ]
then
	echo "Select database:"	
	IFS=$'\n'	
	select conn in $connections
	do	
		connect $conn
		exit 0
	done		
else
	connect $connections 		
	exit 0
fi	                                  
