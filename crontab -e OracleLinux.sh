###DESENCRIPCION DE ARCHIVOS
00 07 * * 2-6 /home/oracle/H2H/h2hprocess.sh
#37 06 * * 2-6 /home/oracle/H2H/h2hprocess.sh
#47 06 * * 2-6 /home/oracle/H2H/h2hprocess.sh
#57 06 * * 2-6 /home/oracle/H2H/h2hprocess.sh

###SUBE MT940 AL ERP###
05 07 * * 2-6 /home/oracle/H2H/putMT940.sh

###DESENCRIPTA PAGOS PDF
00 06 * * 1-6 /home/oracle/H2H/decodepdf.sh
07 06 * * 1-6 /home/oracle/H2H/decodepdf.sh
14 06 * * 1-6 /home/oracle/H2H/decodepdf.sh

###DESCONOCIDOS####
#40 09 * * 2-6 /home/oracle/H2H/h2hprocess.sh
*/30 08-18 * * 1-6 /home/oracle/H2H/decodepagos.sh
#00 06 * * 1-6 /home/oracle/H2H/decodepdf.sh
#00 07 * * 2-6 /home/oracle/H2H/putMT940.sh
00 21 * * 2-6 /home/oracle/H2H/rmMT940.sh

###DEPURA LOGS H2H###
* 05 * * *  /home/oracle/H2H/purgelog.sh
