#!/usr/bin/bash
# bulkexec.sh
# Execute an sql script on a list of databases
# bulkexec.sh databaselistfile script logfile

passfile=./pass.sec

trap ctrl_c INT


function ctrl_c() {
       
	exit 1 
}                                                                             

if [ $# -ne 3 ]; then
	echo "Usage: bukexec.sh dblistfile script logfile"
	exit 1 
fi 

export script=$2
export logfile=$3                                           
PASS=$(openssl enc -aes-256-cbc -d -in $passfile)

connect()
{
	$sqlclexec -S "$USER/$PASS@$1" <$2 
}

total=$(wc -l $1 | cut -d " " -f 1)
curr=1

echo "Script will be executed on $total db":

cat $1


for db in $(cat $1); do
	echo "$curr / $total - $db " | tee -a 
	connect $db $script | tee -a $logfile
	((curr+=1))
done
 	
