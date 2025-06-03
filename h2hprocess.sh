#
#       Instructions:
#
#       Without arguments it will take the date from the server, yesterday (YYMMDD)
#       sh h2hprocess.sh
#
#       With arguments you will need to enter the date you want to use
#       sh h2hprocess.sh YYMMDD
#
#       Author: Nancy Rubi Brise<C3><B1>o Serrano
#       Creation date: 2022-01-14
#

logname="h2hprocessLog_$(date +'%Y%m%d%H%M').log"
logfile="/home/oracle/H2H/logs/$logname"

exec &>> $logfile

if [ ! -z "$1" ]
then
        d_name=$1
else
        d_name=$(date -d "yesterday" +'%y%m%d')
fi
filepath="/home/oracle/H2H/in/"
sftpfrom="/BBVA/Movimientos_Historicos_(FV)/Respuesta/"
sftpto="/BBVA/Comprobantes_Desencriptados/Estado_de_Cuenta/"
outputext=".txt"
user="ORACLEA.USERAMX"
host="201.163.93.3"
port="22"
pass="53cur3P@55AMX2020912"
sftpfile=$filepath"commandsftp.sh"
sqlfile=$filepath"commandsql.sh"

echo "Starting process to get files from H2H" >> $logfile
echo "--------------------------------------" >> $logfile

echo "GETTING PGP FILES FROM SFTP" >> $logfile
        expect -c "
        spawn /bin/sftp -o "BatchMode=no" -P "$port" "$user@$host"
        expect -nocase \"*password:\" { send \"$pass\n\";}
        expect -nocase \"*sftp>\" { send \"cd $sftpfrom\n\";}
        expect -nocase \"*sftp>\" { send \"mget *F$d_name*.pgp $filepath\n\";}
        expect -nocase \"*sftp>\" { send \"bye\n\";}
        " >> $logfile
cd $filepath
filenames=$(ls *F$d_name*.pgp)
if [ -z "$filenames" ]
then
       echo $'\n'"NO FILES FOUND FOR "$d_name$'\n' >> $logfile
else
        echo "DECODING PGP FILES AND CREATING SQL/SFTP FILE" >> $logfile
                cd $filepath
                filenames=$(ls *F$d_name*.pgp)
                for entry in $filenames; do
                        posci=$(echo $entry | grep -aob '.pgp' | grep -oE '[0-9]+')
                        filename=${entry:0:posci}
                        echo $filename >> $logfile
                        echo "F-9Zn'=aj$)x8:;" | gpg --yes --batch --passphrase-fd 0 --output $filename$outputext --decrypt $filename'.pgp'
                done
                rm -r $filepath*F$d_name*.pgp
                rm -r $sftpfile
                rm -r $sqlfile
                echo "expect -c \"" >> $sftpfile
                echo "spawn /bin/sftp -o \"BatchMode=no\" -P \"$port\" \"$user@$host\"" >> $sftpfile
                echo "expect -nocase \\\"*password:\\\" { send \\\"$pass\\n\\\";}" >> $sftpfile
                echo "expect -nocase \\\"*sftp>\\\" { send \\\"cd $sftpfrom\\n\\\";}" >> $sftpfile
                echo "expect -c \"" >> $sqlfile
                echo "spawn /u01/app/oracle/product/19.0.0.0/dbhome_1/bin/sqlplus ALMEX_VOUCHER/90kf8.23ASiw)#@//150.136.114.231:1521/pdbfeprd.sub05191742460.vcnsoaprod.oraclevcn.com" >> $sqlfile
                echo "--------------------------------------" >> $logfile
                echo "Files processed:" >> $logfile
                filenamedcd=$(ls *F$d_name*$outputext)
                for entry in $filenamedcd; do
                        posci=$(echo $entry | grep -aob $outputext | grep -oE '[0-9]+')
                        filename=${entry:0:posci}
                        echo "expect -nocase \\\"*sftp>\\\" { send \\\"rm $filename.pgp\\n\\\";}" >> $sftpfile
                        echo "expect -nocase \\\"*SQL>\\\" { send \\\"INSERT INTO XXALM_H2H_FILES VALUES(files_seq.nextval,'"$filename$outputext"',sysdate);\\n\\\";}" >> $sqlfile
                        echo $filename >> $logfile
                done
                echo "expect -nocase \\\"*sftp>\\\" { send \\\"bye\\n\\\";}" >> $sftpfile
                echo "\"" >> $sftpfile
                echo "expect -nocase \\\"*SQL>\\\" { send \\\"COMMIT;\\n\\\";}" >> $sqlfile
                echo "expect -nocase \\\"*SQL>\\\" { send \\\"EXIT;\\n\\\";}" >> $sqlfile
                echo "\"" >> $sqlfile
                echo "--------------------------------------" >> $logfile

        echo "INSERTING ROWS AT SQL TABLE" >> $logfile
                sh $sqlfile >> $logfile

        echo "REMOVE THE PGP FILES SUCCESFULLY DECRIPTED FROM SFTP" >> $logfile
                sh $sftpfile >> $logfile

        echo "UPLOADING FILES TO SFTP" >> $logfile
                expect -c "
                spawn /bin/sftp -o "BatchMode=no" -P "$port" "$user@$host"
                expect -nocase \"*password:\" { send \"$pass\n\";}
                expect -nocase \"*sftp>\" { send \"cd $sftpto\n\";}
                expect -nocase \"*sftp>\" { send \"mput $filepath*F$d_name*\n\";}
                expect -nocase \"*sftp>\" { send \"bye\n\";}
                " >> $logfile

        rm -r $sftpfile >> $logfile
        rm -r $sqlfile >> $logfile
fi
echo $'\n'"FINISHED" >> $logfile

exit 0
