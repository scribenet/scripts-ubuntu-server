#!/usr/bin/env bash
output=`pidof -s /usr/Adaptec_Event_Monitor/EventMonitor`
ret=$?
if [[ "$ret" == "0" ]]
then
  echo "EventMonitor running with pid: $output"
else
  echo "EventMonitor not running."
fi
exit $ret
