#!/usr/bin/env bash
pid=`pidof -s /usr/sbin/sendmail-mta`
ret=$?
if [[ "$ret" == "0" ]]
then
  echo "Sendmail MTA running with pid: $pid"
else
  echo "Sendmail MTA not running."
fi
exit $ret
