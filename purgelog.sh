echo 'clear ..'

find /home/oracle/H2H/logs -name "*" -type f -mtime +30 -exec rm -f {} \;
find /home/oracle/H2H/in -name "*" -type f -mtime +30 -exec rm -f {} \;


echo 'end ..'
