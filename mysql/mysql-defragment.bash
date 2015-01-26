#!/bin/bash
echo "MYSQL TABLE OPTOMIZER SCRIPT v0.5"
echo ""
echo "Enter the password for the mysql root@localhost user when prompted."
mysql_config_editor set --skip-warn --login-path=local --host=localhost --user=root --password

mysql --login-path=local -NBe "SHOW DATABASES;" | grep -v 'lost+found' | while read database ; do
mysql --login-path=local -NBe "SHOW TABLE STATUS;" $database | while read name engine version rowformat rows avgrowlength datalength maxdatalength indexlength datafree autoincrement createtime updatetime checktime collation checksum createoptions comment ; do
  if [ "$datafree" != "NULL" ] && [ "$datafree" -gt 0 ] ; then
   	fragmentation=$(($datafree * 100 / $datalength))
   	echo " - $database.$name is $fragmentation% fragmented."
	echo "   |- Size      : $(( $datalength / 1024 / 1024 )) MB"
	echo -n "   |- Action    : "
   	if [ "$database.$name" == "world-dev.ProjectFileContent" ] ; then
   		echo "Skipping per explicit request."
   	else
   		echo "Performing optomization routing."
		echo "   |- Command   : mysql --login-path=local -NBe \"OPTIMIZE TABLE '$name';\" \"$database\""
		echo -n "   |- Optimizing:"
	   	mysql --login-path=local -NBe "OPTIMIZE TABLE $name;" "$database" > /dev/null
		if [ "$?" -eq 0 ]; then
			echo "complete."
		else
			echo "FAILURE!"
			sleep 20
		fi
	fi
	echo ""
  fi
done
done
