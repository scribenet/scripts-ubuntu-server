INTERVAL=5
DIR=/tmp/mysql-bench/
PREFIX=$INTERVAL-sec-status
RUNFILE=/tmp/mysql.run
mkdir -p $DIR
mysql -uroot -e 'SHOW GLOBAL VARIABLES' >> $DIR/mysql-variables
while test -e $RUNFILE; do
	file=$(date +%F_%I)
	sleep=$(date +%s.%N | awk "{print $INTERVAL - (\$1 % $INTERVAL)}")
	sleep $sleep
	ts="$(date +"TS %s.%N %F %T")"
	loadavg="$(uptime)"
	echo "$ts $loadavg" >> $DIR/$PREFIX-${file}-status
	mysql -uroot -e 'SHOW GLOBAL STATUS' >> $DIR/$PREFIX-${file}-status & echo "$ts $loadavg" >> $DIR/$PREFIX-${file}-innodbstatus
	mysql -uroot -e 'SHOW ENGINE INNODB STATUS\G' >> $DIR/$PREFIX-${file}-innodbstatus & echo "$ts $loadavg" >> $DIR/$PREFIX-${file}-processlist
	mysql -uroot -e 'SHOW FULL PROCESSLIST\G' >> $DIR/$PREFIX-${file}-processlist & echo $ts
done
echo Exiting because $RUNFILE does not exist.
