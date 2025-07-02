#!/bin/bash
# Nombre de archivo de log con timestamp
#
#       Instructions:
#
#       Without arguments it will take the date from the server, yesterday (YYMMDD)
#       sh decodepdf.sh
#
#       With arguments you will need to enter the date you want to use
#       sh decodepdf.sh YYMMDD
#
#       Author: Nancy Rubi Brise<C3><B1>o Serrano
#       Creation date: 2022-01-14
#

logname="decodepdfLog_$(date +'%Y%m%d%H%M').log"
logfile="/home/oracle/H2H/logs/$logname"

exec &>> $logfile

# Si se proporciona una fecha como argumento, se usa. Si no, se calcula la fecha por defecto (ayer o hoy)
if [ ! -z "$1" ]
then
        d_name=$1
else
        d_name=$(date -d "yesterday" +'%y%m%d')
fi
filepath="/home/oracle/H2H/pagos/tmp_pdf/"
sftpfrom="/BBVA/Comprobantes_SIT_PDF/Respuesta/"
sftpto="/BBVA/Comprobantes_Desencriptados/PDF/"
outputext=""
user="ORACLEA.USERAMX"
host="201.163.93.3"
port="22"
pass="53cur3P@55AMX2020912"
sftpfile=$filepath"commandsftp.sh"


## Getsemani Avila 18/06/2025
backup_local="/home/oracle/H2H/backup_local"
backup_ftp="/home/oracle/H2H/backup_ftp"
backup_trash="/BBVA/QuotesTRASHquoteS/Tesoreria"
fecha_ejecucion=$(date +'%Y%m%d_%H%M%S')
# ^^^^^^^^^^^^^^^^^^^^^^^^^^


echo "Starting process to get files from H2H" >> $logfile
echo "--------------------------------------" >> $logfile

echo "GETTING PGP FILES FROM SFTP" >> $logfile
        # Bloque expect para conexión SFTP
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
                        # Desencripta el archivo .pgp
                        echo "F-9Zn'=aj$)x8:;" | gpg --yes --batch --passphrase-fd 0 --output $filename$outputext --decrypt $filename'.pgp'
                done

                # Getsemani Avila 18/06/2025
                ## rm -r $filepath*F$d_name*.pgp
                mkdir -p "$backup_local"
                for entry in $filepath*F$d_name*.pgp; do
                    [ -f "$entry" ] || continue
                    filename=$(basename "$entry")
                    ext="${filename##*.}"
                    name="${filename%.*}"
                    newname="$name - $fecha_ejecucion.$ext"
                    mv "$entry" "$backup_local/$newname"
                done
                ## rm -r $sftpfile
                mv "$sftpfile" "$backup_local/commandsftp - $fecha_ejecucion.sh"
                # ^^^^^^^^^^^^^^^^^^^^^^^^^^

                # Bloque expect para conexión SFTP
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
                        # Getsemani Avila 18/06/2025
                        # echo "expect -nocase \\\"*sftp>\\\" { send \\\"rm $filename.pgp\\n\\\";}" >> $sftpfile
                        backup_remote_path="$backup_trash$sftpfrom"
                        new_remote_name="$filename - $fecha_ejecucion.pgp"

                        # crea el directorio si no existe
                        echo "expect -nocase \\\"*sftp>\\\" { send \\\"mkdir -p $backup_remote_path\\n\\\";}" >> $sftpfile
                        # mueve (rename) el archivo
                        echo "expect -nocase \\\"*sftp>\\\" { send \\\"rename $filename.pgp $backup_remote_path/$new_remote_name\\n\\\";}" >> $sftpfile
                        # ^^^^^^^^^^^^^^^^^^^^^^^^^^
                        echo $filename >> $logfile
                done
                echo "expect -nocase \\\"*sftp>\\\" { send \\\"bye\\n\\\";}" >> $sftpfile
                echo "\"" >> $sftpfile
                echo "--------------------------------------" >> $logfile

        echo "REMOVE THE PGP FILES SUCCESFULLY DECRIPTED FROM SFTP" >> $logfile
                sh $sftpfile >> $logfile

        echo "UPLOADING FILES TO SFTP" >> $logfile
                # Bloque expect para conexión SFTP
                expect -c "
                spawn /bin/sftp -o "BatchMode=no" -P "$port" "$user@$host"
                expect -nocase \"*password:\" { send \"$pass\n\";}
                expect -nocase \"*sftp>\" { send \"cd $sftpto\n\";}
                expect -nocase \"*sftp>\" { send \"mput $filepath*F$d_name*\n\";}
                expect -nocase \"*sftp>\" { send \"bye\n\";}
                " >> $logfile

        # Getsemani Avila 18/06/2025
        ## rm -r $filepath*F$d_name*$outputext >> $logfile
        for entry in $filepath*F$d_name*$outputext; do
            [ -f "$entry" ] || continue
            filename=$(basename "$entry")
            ext="${filename##*.}"
            name="${filename%.*}"
            newname="$name - $fecha_ejecucion.$ext"
            mv "$entry" "$backup_local/$newname"
        done
        # ^^^^^^^^^^^^^^^^^^^^^^^^^^
        rm -r $sftpfile >> $logfile

fi
echo $'\n'"FINISHED" >> $logfile

# Fin del script con salida exitosa
exit 0
