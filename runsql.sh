#!/usr/bin/bash
# Connect to a database, if more than one match a menu is shown to select connection
# connect.sh database

export passfile=./pass.sec

trap ctrl_c INT

function ctrl_c() {
       	chtitle "Cygwin"
	exit 1 
}                                                                             

if [ $# -ne 2 ]; then
	echo "Usage: runsql.sh db sqlscript"
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
	$sqlclexec "$USER/$PASS@$1" '@'$2 
	chtitle "Cygwin"
}

getpass()
{
if [ -v $PASS ]; then
        PASS=$(openssl enc -aes-256-cbc -d -in $passfile)
	if [ $? -ne 0 ]; then
		echo "Unable to decrypt password"
		exit 1
	fi
fi
}

connections=$(findtns $1)


if [ -z $(echo "$connections" | head -1)  ];
then
	echo "No Databases found containing $1."
	exit 1
fi

if [ $(echo -e "$connections" | wc -l) -gt 1 ]
then
	echo "Select database:"	
	IFS=$'\n'	
	select conn in $connections
	do	
		break	
	done		
else
	conn=$connections
fi

getpass
chtitle $conn
connect $conn $2	                               
exit 0   
