#!/bin/bash
## radar_ora.sh
###	lettura variabili ambiente
. /home/meteo/conf/default.conf
. /home/meteo/.bashrc
. /home/meteo/radar_ora/variabili_radar
declare -x LANG="us_US.UTF-8"
export LC_TIME="en_GB"
export LC_NUMERIC=C

if [ "$1" == "--help" ]
then
	echo "Utilizzo: $0 <data di inizio cumulazione (formato aaaammgghh, ad esempio 2007061512)>"
	exit
fi

echo "--parsing data da argomento o da orologio di sistema"

if [ $1 ]
then
	echo "Passata data da riga di comando"
	data=$1
	echo "data del file in esame---------> $data"
	ora=${data:8:2}
	echo "ora del file in esame---------> $ora"
	giorno=${data:6:2}
	echo "giorno del file in esame---------> $giorno"
	mese1=${data:4:2}
	echo "mese del file in esame---------> $mese1"
	anno1=${data:0:4}
	echo "anno del file in esame---------> $anno1"
	mese=`date --date $anno1$mese1$giorno +%b` && echo $mese
	anno=`date --date $anno1$mese1$giorno +%y` && echo $anno
else
	echo "Data ricavata da orologio di sistema:"
	data=$(date -d '1 hour ago' +%Y%m%d%H)
	echo "data del file in esame---------> $data"
	ora=$(date -d '1 hour ago' +%H)
	echo "ora del file in esame---------> $ora"
	giorno=$(date -d '1 hour ago' +%d)
	echo "giorno del file in esame---------> $giorno"
	mese=$(date -d '1 hour ago' +%b)
	mese1=$(date -d '1 hour ago' +%m)
	echo "mese del file in esame---------> $mese1"
	anno=$(date -d '1 hour ago' +%y)
	anno1=$(date -d '1 hour ago' +%Y)
	echo "anno del file in esame---------> $anno1"
fi

fls=lista.txt
nomefile_cumulata="cumulata_oraria_"$data".dat"

###	controllo sovrapposizione processi
echo "--impostazioni lockdir"
export LOCKDIR="$TMP_DIR/`basename $0 .sh`.lock" && echo "lockdir -----> $LOCKDIR"
T_MAX=3600
if mkdir "$LOCKDIR" 2>/dev/null
then
        echo "acquisito lockdir: $LOCKDIR" 
        echo $$ > $LOCKDIR/PID && echo "PID di questo processo: `cat $LOCKDIR/PID`"
else
        echo "Script \"$nomescript.sh\" già in esecuzione alle ore `date +%H%M` con PID: $(<$LOCKDIR/PID)"
        echo "controllo durata esecuzione script"
        ps --no-heading -o etime,pid,lstart -p $(<$LOCKDIR/PID)|while read PROC_TIME PROC_PID PROC_LSTART
        do
                SECONDS=$[$(date +%s) - $(date -d"$PROC_LSTART" +%s)]
                echo "------Script \"$nomescript.sh\" con PID $(<$LOCKDIR/PID) in esecuzione da $SECONDS secondi"
                if [ $SECONDS -gt $T_MAX ]
                then
                        echo "$PROC_PID in esecuzione da più di $T_MAX secondi, lo killo"
                        pkill -15 -g $PROC_PID
                fi
        done
        echo "*********************************************************"
        exit
fi

trap "echo \"--Rimozione con trap\"; 
rm -vR $LOCKDIR;
#rm -fv $TMP_DIR/*;
rm -v $RADARDIR_CUM/info.txt;
rm -v $RADARDIR_CUM/listaUIL.txt
rm -v $RADARDIR_CUM/cumulata_oraria.dat;
rm -v $RADARDIR_CUM/*.gri; 
rm -v $RADARDIR_CUM/*.grd;
rm -v $SCARICO_DIR/*.$data*.tiff;
rm -v $GRADS/tmp*.ctl;
rm -v $GRADS/cumulata_oraria.ctl;
rm -v $GRADS/$nomefile_cumulata;
echo;
echo \"******* Fine script  `date` *****************\";
exit" EXIT HUP INT QUIT TERM
###	fine controllo

echo "--ftp sul sito ftp arpa $host per scaricare i dati"
ncftpls ftp://${usr}:${pwr}@${host}/Prisma/meteoswiss.radar.precip.$data* > $LOCKDIR/$fls
echo "codice di uscita di ncftpls: $?"
echo

if [ ! -s "$LOCKDIR/$fls" ]
then
	rm $LOCKDIR/$fls
#	echo -e "--Non ci sono dati su FTP server; li cerco su $SERVER\n"
        echo -e "--Non ci sono dati su FTP server; li cerco su $SERVER_DATI\n"

#	ssh $SERVER "ls -1 /dati/radar/$anno1$mese1/meteoswiss.radar.precip.$data*" > $TMP_DIR/$fls
        ssh $SERVER_DATI "ls -1 /dati/radar/$anno1$mese1/meteoswiss.radar.precip.$data*" > $LOCKDIR/$fls

	if [ ! -s "$LOCKDIR/$fls" ]
	then
		echo "--Non ci sono dati da scaricare su $SERVER_DATI: esco dal programma"
		exit
	else
		echo -e "--Presenti questi files da scaricare da $SERVER_DATI:\n`cat $LOCKDIR/$fls`"
		cd $SCARICO_DIR
		scp $SERVER_DATI:/dati/radar/$anno1$mese1/"meteoswiss.radar.precip."$data"*" .
	fi
else
  echo -e "--Presenti questi files da scaricare da $host:\n`cat $LOCKDIR/$fls`"
	for nomefile in `cat $LOCKDIR/$fls`
	do
	  annomese_dir=`echo $nomefile|awk '{print substr($0,25,6)}'` && echo $annomese_dir
  	cd $SCARICO_DIR
  	ncftpget $node $SCARICO_DIR Prisma/$nomefile
	done
fi

###	inizio elaborazioni
echo

find $SCARICO_DIR -name "*.$data*.tiff" | sort > $LOCKDIR/lista_radar.txt && echo -e "--Lista files scaricati:\n`cat $LOCKDIR/lista_radar.txt`\n"

echo "--Informazioni sui radar presenti"
for nome in $SCARICO_DIR/*.$data*.tiff
do 
	gdalinfo $nome |grep "RADAR="|cut -d" " -f4|cut -d"=" -f2 >> $LOCKDIR/nomi_radar.txt
done
grep A $LOCKDIR/nomi_radar.txt |wc -l > $LOCKDIR/albis.txt && cat $LOCKDIR/albis.txt
grep D $LOCKDIR/nomi_radar.txt |wc -l > $LOCKDIR/dole.txt && cat $LOCKDIR/dole.txt
grep L $LOCKDIR/nomi_radar.txt |wc -l > $LOCKDIR/lema.txt && cat $LOCKDIR/lema.txt
grep P $LOCKDIR/nomi_radar.txt |wc -l > $LOCKDIR/plaine.txt && cat $LOCKDIR/plaine.txt

echo "--Converto in coordinate lat lon con script R"
Rscript --save --verbose $BASE/converti_ll.r $LOCKDIR/lista_radar.txt $RADARDIR_CUM

cd $RADARDIR_CUM
echo
echo "--Calcolo la cumulata ORARIA in coordinate lat lon con programma cumula_ora"
find . -name "meteoswiss.radar.precip.*.gri" | sort > listaUIL.txt

### lancio programma per cumulare
$BASE/cumula_ora
if [ $? == "0" ]
then
	echo
	echo -e "--Terminato programma cumula_ora senza errori\n"
else
	echo -e "--Terminato programma cumula_ora CON ERRORI!"
fi

echo "--Rinomino file prodotto dal programma cumula_ora"
cp -v cumulata_oraria.dat $GRADS/$nomefile_cumulata

###	lancio script R per statistica su cumulata e sistemo il file con shell
echo "--Script R per statistica"
Rscript --verbose $BASE/stat_radar.r $GRADS/$nomefile_cumulata
while read inputline
do
	printf "%s  %.1f  %.1f  %.1f\n" $inputline >> $LOCKDIR/statistica_radar.txt
done < $LOCKDIR/stat_radar.txt

cat $LOCKDIR/statistica_radar.txt

### preparo il file ctl
echo
echo "--Preparazione CTL GRADS--"
primofile=`awk '(NR <2) {print$1}' $LOCKDIR/$fls` && echo $primofile
stringa=$ora":00Z"$giorno$mese$anno && echo $stringa 
stringa1=$anno1$mese1$giorno$ora && echo $stringa1
sed '1s/cumulata_oraria.dat/'$nomefile_cumulata'/' $GRADS/grads_ll_orig.ctl > $GRADS/tmp1.ctl
sed '9s/20:00Z07oct04/'$stringa'/' $GRADS/tmp1.ctl > $GRADS/tmp.ctl

numeroelaborazioni=`tail -1 $RADARDIR_CUM/info.txt|awk '(NR<2) {print $7}'` && echo "numero elaborazioni: $numeroelaborazioni"
sed '9s/1 LINEAR/'$numeroelaborazioni' LINEAR/' $GRADS/tmp.ctl > $GRADS/cumulata_oraria.ctl

### produzione immagini con grads
echo "--Script GRADS per plot"
cd $GRADS
$OPENGRADS -blc oraria_ll.gs

convert -font helvetica -pointsize 15 -fill blue -draw "text 2,560 'Q   50  90  100'" temp.png temp.png
i=10
while read inputline
do
	posiz=$((580+$i))
	convert -font helvetica -pointsize 15 -draw "text 2,'$posiz' '$inputline'" temp.png temp.png
	i=$((i+15))
done < $LOCKDIR/statistica_radar.txt

mv temp.png cumulata_ora_$stringa1.png

### archviazione su webserver
echo "--Archiviazione su webserver"
#ssh $SERVER "! mkdir $RADAR_SERVER/$anno1$mese1"
#scp cumulata_ora_$stringa1.png $SERVER:$RADAR_SERVER/$anno1$mese1 #&& rm -v cumulata_ora_$stringa1.png

ssh $SERVER1 "! mkdir $RADAR_SERVER1/$anno1$mese1"
scp cumulata_ora_$stringa1.png $SERVER1:$RADAR_SERVER1/$anno1$mese1 #&& rm -v cumulata_ora_$stringa1.png

### copia su web esterno e rimozione su web esterno vecchie immagini
ssh $SERVER_EXT "! mkdir $RADAR_SERVER_EXT/$anno1$mese1"
scp cumulata_ora_$stringa1.png $SERVER_EXT:$RADAR_SERVER_EXT/$anno1$mese1 && rm -v cumulata_ora_$stringa1.png

echo "--Rimozione files vecchi da webserver"
echo -e "Rimuovo questi files da $SERVER_EXT:\n `ssh $SERVER_EXT 'find /var/www/meteo/ghost/radar/radar_ora -name "*.png" -mtime +62 -exec rm -vR {} \;'`" && echo -e "Rimozione remota terminata\n"
echo -e "Rimuovo directory vuote da $SERVER_EXT:\n `ssh $SERVER_EXT 'find /var/www/meteo/ghost/radar/radar_ora -type d -empty -exec rmdir {} \;'`" && echo -e "Rimozione remota terminata\n"

exit

