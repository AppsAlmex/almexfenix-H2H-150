#
#       Instructions:
#
#       You need to replace the FILENAME.EXT with the name and extension of the file that you want to remove from SFTP
#       sh rmSFTP.sh FILENAME.EXT
#
#       Author: Nancy Rubi Brise<C3><B1>o Serrano
#       Creation date: 2022-01-20
#

logname="rmMT940Log_$(date +'%Y%m%d%H%M').log"
logfile="/home/oracle/H2H/logs/$logname"

exec &>> $logfile

filepath="/home/oracle/H2H/in/"
sftpto="/BBVA/Comprobantes_Desencriptados/MT940"
user="ORACLEA.USERAMX"
host="201.163.93.3"
port="22"
pass="53cur3P@55AMX2020912"

echo "Starting process" >> $logfile
echo "--------------------------------------" >> $logfile
   echo "REMOVING FILE FROM SFTP" >> $logfile
                expect -c "
                spawn /bin/sftp -o "BatchMode=no" -P "$port" "$user@$host"
                expect -nocase \"*password:\" { send \"$pass\n\";}
                expect -nocase \"*sftp>\" { send \"cd $sftpto\n\";}
                expect -nocase \"*sftp>\" { send \"rm MT940.txt\n\";}
                expect -nocase \"*sftp>\" { send \"bye\n\";}
                " >> $logfile
echo $'\n'"FINISHED" >> $logfile

exit 0
