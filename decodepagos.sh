#
#       Instructions:
#
#       Without arguments it will take the date from the server, today (YYMMDD)
#       sh dedodepagos.sh
#
#       With arguments you will need to enter the date you want to use
#       sh dedodepagos.sh YYMMDD
#
#       Author: Nancy Rubi Brise<C3><B1>o Serrano
#       Creation date: 2022-01-14
#

logname="decodepagosLog_$(date +'%Y%m%d%H%M').log"
logfile="/home/oracle/H2H/logs/$logname"

exec &>> $logfile

if [ ! -z "$1" ]
then
        d_name=$1
else
        d_name=$(date +'%y%m%d')
fi
filepath="/home/oracle/H2H/pagos/tmp_pagos/"
sftpfrom="/BBVA/SIT_Documentos/Respuesta/"
sftpto="/BBVA/Comprobantes_Desencriptados/Respuesta_pagos/"
outputext=".txt"
user="ORACLEA.USERAMX"
host="201.163.93.3"
port="22"
pass="53cur3P@55AMX2020912"
sftpfile=$filepath"commandsftp.sh"

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
                echo "expect -c \"" >> $sftpfile
                echo "spawn /bin/sftp -o \"BatchMode=no\" -P \"$port\" \"$user@$host\"" >> $sftpfile
                echo "expect -nocase \\\"*password:\\\" { send \\\"$pass\\n\\\";}" >> $sftpfile
                echo "expect -nocase \\\"*sftp>\\\" { send \\\"cd $sftpfrom\\n\\\";}" >> $sftpfile
                echo "--------------------------------------" >> $logfile
                echo "Files processed:" >> $logfile
                filenamedcd=$(ls *F$d_name*$outputext)
                for entry in $filenamedcd; do
                        posci=$(echo $entry | grep -aob $outputext | grep -oE '[0-9]+')
                        filename=${entry:0:posci}
                        echo "expect -nocase \\\"*sftp>\\\" { send \\\"rm $filename.pgp\\n\\\";}" >> $sftpfile
                        echo $filename >> $logfile
                done
                echo "expect -nocase \\\"*sftp>\\\" { send \\\"bye\\n\\\";}" >> $sftpfile
                echo "\"" >> $sftpfile
                echo "--------------------------------------" >> $logfile

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

        rm -r $filepath*F$d_name*$outputext >> $logfile
        rm -r $sftpfile >> $logfile
fi
echo $'\n'"FINISHED" >> $logfile

exit 0
