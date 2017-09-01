#################################################################################
#
# FILE.......: 	radar_giorno.sh
# -------------------------------------------------------------------------------
# PURPOSE....: 	Conversione immagini radar Monte Lema
#		e calcolo cumulata giornaliera
#								
# -------------------------------------------------------------------------------
# CREATED....: 	luglio 2012 
#
#                  DATE                      DESCRIPTION
#
#################################################################################
###	lettura variabili ambiente
. /home/meteo/conf/default.conf
. /home/meteo/.bashrc
. /home/meteo/radar_giorno/variabili_radar && cat /home/meteo/radar_giorno/variabili_radar
declare -x LANG="us_US.UTF-8"
export LC_TIME="en_GB"
export LC_NUMERIC=C

if [ "$1" == "--help" ]
then
	echo "Utilizzo: $0 <data di inizio cumulazione (formato aaaammgg, ad esempio 20070615)>"
	exit
fi

echo

if [ $1 ]
then
	echo "Passata data da riga di comando"
	data=$1
	echo "data del file in esame---------> $data"
#	ora=${data:8:2}
#	echo "ora del file in esame---------> $ora"
	giorno=${data:6:2}
	echo "giorno del file in esame---------> $giorno"
	mese1=${data:4:2}
	echo "mese del file in esame---------> $mese1"
	anno1=${data:0:4}
	echo "anno del file in esame---------> $anno1"
	mese=`date --date $anno1$mese1$giorno +%b` && echo $mese
	anno=`date --date $anno1$mese1$giorno +%y` && echo $anno
else
	echo "Data ricavata da orologio di sistema"
	data=$(date -d '1 hour ago' +%Y%m%d)
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
nomefile_cumulata="cumulata_giorno_"$data".dat" && echo "-------> nome del file cumulato: $nomefile_cumulata"

echo " ******* Inizio script: `date` ***************** "
echo

### controllo sovrapposizione processi
echo
echo "--Informazioni sul processo in esecuzione"
LOCKFILE="$TMP_DIR/`basename $0 .sh`.pid" && echo "file di LOCK: $LOCKFILE"
if [ -e $LOCKFILE ] && kill -0 `cat $LOCKFILE`
then
        echo "`basename $0` già in esecuzione: uscita dallo script."
        exit
fi

trap "echo; 
rm -fv $LOCKFILE;
rm -fv $TMP_DIR/*;
rm -v $RADARDIR_CUM/info.txt;
rm -v $RADARDIR_CUM/listaUIL.txt
rm -v $GRADS/tmp*.ctl;
rm -v $SCARICO_DIR/*.$data*.tiff;
rm -v $RADARDIR_CUM/*.grd;
rm -v $RADARDIR_CUM/*.gri; 
rm -v $SCARICO_DIR/*.$data*.tiff;
rm -v $GRADS/cumulata_giorno.ctl;
rm -v $BASE/*.png
echo;
echo \"******* Fine script  `date` *****************\";
exit" INT TERM EXIT


echo $$ > $LOCKFILE && echo "PID di questo processo: `cat $LOCKFILE`"
###	fine controllo

orainizio=$(date +%s)

echo "--ftp sul sito ftp arpa $host per scaricare i dati"
ncftpls ftp://${usr}:${pwr}@${host}/Prisma/meteoswiss.radar.precip.$data* > $TMP_DIR/$fls
echo "codice di uscita di ncftpls: $?"
echo

if [ ! -s "$TMP_DIR/$fls" ]
then
	rm $TMP_DIR/$fls
	echo -e "--Non ci sono dati su FTP server; li cerco su $SERVER_DATI\n"
	ssh $SERVER_DATI "ls -1 /dati/radar/$anno1$mese1/meteoswiss.radar.precip.$data*" > $TMP_DIR/$fls
	if [ ! -s "$TMP_DIR/$fls" ]
	then
		echo "--Non ci sono dati da scaricare su $SERVER_DATI: esco dal programma"
		exit
	else
		echo -e "--Presenti questi files da scaricare da $SERVER_DATI:\n`cat $TMP_DIR/$fls`"
		cd $SCARICO_DIR
		scp $SERVER_DATI:/dati/radar/$anno1$mese1/"meteoswiss.radar.precip."$data"*" .
	fi
else
  echo -e "--Presenti questi files da scaricare da $host:\n`cat $TMP_DIR/$fls`"
	for nomefile in `cat $TMP_DIR/$fls`
	do
	  annomese_dir=`echo $nomefile|awk '{print substr($0,25,6)}'` && echo $annomese_dir
  	cd $SCARICO_DIR
  	ncftpget $node $SCARICO_DIR Prisma/$nomefile
	done
fi

###	inizio elaborazioni
echo

find $SCARICO_DIR -name "*.$data*.tiff" | sort > $TMP_DIR/lista_radar.txt && echo -e "--Lista files scaricati:\n`cat $TMP_DIR/lista_radar.txt`\n"

echo `date +"%Y-%m-%d %H:%M:%S"`" > --Informazioni sui radar presenti"
for nome in $SCARICO_DIR/*.$data*.tiff
do 
	gdalinfo $nome |grep "RADAR="|cut -d" " -f4|cut -d"=" -f2 >> $TMP_DIR/nomi_radar.txt
  echo $(basename $nome) $(gdalinfo $nome|grep -E "ColorInterp |Color" |cut -d"," -f2)>>$BASE/info_band/info_band.txt
done

grep A $TMP_DIR/nomi_radar.txt |wc -l > $TMP_DIR/albis.txt && cat $TMP_DIR/albis.txt
grep D $TMP_DIR/nomi_radar.txt |wc -l > $TMP_DIR/dole.txt && cat $TMP_DIR/dole.txt
grep L $TMP_DIR/nomi_radar.txt |wc -l > $TMP_DIR/lema.txt && cat $TMP_DIR/lema.txt
grep P $TMP_DIR/nomi_radar.txt |wc -l > $TMP_DIR/plaine.txt && cat $TMP_DIR/plaine.txt

echo `date +"%Y-%m-%d %H:%M:%S"`" > --Converto in coordinate lat lon con script R"
Rscript --save --verbose $BASE/converti_ll.r $TMP_DIR/lista_radar.txt $RADARDIR_CUM

cd $RADARDIR_CUM
echo
echo `date +"%Y-%m-%d %H:%M:%S"`" > --Calcolo la cumulata GIORNALIERA in coordinate lat lon con programma cumula_giorno"
find . -name "meteoswiss.radar.precip.*.gri" | sort > listaUIL.txt

### lancio programma per cumulare
$BASE/cumula_giorno
if [ $? == "0" ]
then
	echo
	echo -e "--Terminato programma cumula_giorno senza errori\n"
else
	echo -e "--Terminato programma cumula_giorno CON ERRORI!"
fi

echo "--Rinomino file prodotto dal programma cumula_giorno"
mv -v cumulata_giorno.dat $GRADS/$nomefile_cumulata

###	lancio script R per statistica su cumulata e sistemo il file con shell
Rscript --verbose $BASE/stat_radar.r $GRADS/$nomefile_cumulata
while read inputline
do
	printf "%s  %.1f  %.1f  %.1f\n" $inputline >> $TMP_DIR/statistica_radar.txt
done < $TMP_DIR/stat_radar.txt
cat $TMP_DIR/statistica_radar.txt
#

orafine=$(date +%s)
differenza=$(($orafine - $orainizio))
tempo_minuti=$(($differenza / 60)) && echo "tempo di plottaggio in minuti: $tempo_minuti min"

### preparo il file ctl
primofile=`awk '(NR <2) {print$1}' $TMP_DIR/$fls` && echo $primofile
#stringa=$ora":00Z"$giorno$mese$anno && echo $stringa
stringa="00:00Z"$giorno$mese$anno && echo $stringa 
stringa1=$anno1$mese1$giorno && echo $stringa1
sed '1s/cumulata_giorno.dat/'$nomefile_cumulata'/' $GRADS/grads_ll_orig.ctl > $GRADS/tmp1.ctl
sed '9s/20:00Z07oct04/'$stringa'/' $GRADS/tmp1.ctl > $GRADS/tmp.ctl

numeroelaborazioni=`tail -1 $RADARDIR_CUM/info.txt|awk '(NR<2) {print $7}'` && echo "numero elaborazioni: $numeroelaborazioni"
sed '9s/1 LINEAR/'$numeroelaborazioni' LINEAR/' $GRADS/tmp.ctl > $GRADS/cumulata_giorno.ctl

### produzione immagini con grads e stampa informazioni sui quantili
echo `date +"%Y-%m-%d %H:%M:%S"`" > produzione immagini con grads e stampa informazioni sui quantili"
cd $GRADS
$GRADS_EXE -blc giorno_ll.gs

convert -font helvetica -pointsize 15 -fill blue -draw "text 2,560 'Q   50  90  100'" temp.png temp.png
i=10
while read inputline
do
	posiz=$((580+$i))
	convert -font helvetica -pointsize 15 -draw "text 2,'$posiz' '$inputline'" temp.png temp.png
	i=$((i+15))
done < $TMP_DIR/statistica_radar.txt

mv temp.png cumulata_giorno_$stringa1.png

###	calcolo statistica comunale e generazione immagini
cd $BASE
Rscript --verbose comuni_stat.r $GRADS/$nomefile_cumulata
montage -border 1 -bordercolor black -geometry '1x1+0+0<' -tile 3x4 Bergamo.png Brescia.png Como.png Cremona.png Lecco.png Lodi.png Mantua.png Milano.png "Monza and Brianza.png" Pavia.png Sondrio.png Varese.png comuni_$stringa1.png
#mv -v comuni_$stringa1.png $BASE/img
rm -v comuni_$stringa1.png

./comuni_stat_test.r $GRADS/$nomefile_cumulata $data
montage -geometry 1024x1024 -tile 1x2 vdadaily_$data.png vda_$data.png ao_$data.png
ncftpput -u ammi -p f104 ftp.arpalombardia.it temp/ ao_$data.png
rm -v ao_$data.png

### archviazione su webserver
echo `date +"%Y-%m-%d %H:%M:%S"`" > copio files su ghost..."

ssh $SERVER1 "! mkdir $RADAR_SERVER_GIORNO1/$anno1$mese1"
scp $GRADS/cumulata_giorno_$stringa1.png $SERVER1:$RADAR_SERVER_GIORNO1/$anno1$mese1 #&& rm -v cumulata_giorno_$stringa1.png

### copia su web esterno e rimozione su web esterno vecchie immagini
echo "copio files su ghost esterno e rimuovo file vecchi..."
ssh $SERVER_EXT "! mkdir $RADAR_SERVER_GIORNO_EXT/$anno1$mese1"
scp $GRADS/cumulata_giorno_$stringa1.png $SERVER_EXT:$RADAR_SERVER_GIORNO_EXT/$anno1$mese1 && rm -v $GRADS/cumulata_giorno_$stringa1.png
echo
echo -e "Rimuovo questi files da $SERVER_EXT:\n `ssh $SERVER_EXT 'find /var/www/meteo/ghost/radar/radar_giorno -name "*.png" -mtime +62 -exec rm -vR {} \;'`" && echo -e "Rimozione remota terminata\n"
echo -e "Rimuovo directory vuote da $SERVER_EXT:\n `ssh $SERVER_EXT 'find /var/www/meteo/ghost/radar/radar_giorno -type d -empty -exec rmdir {} \;'`" && echo -e "Rimozione remota terminata\n"

echo " ******* Fine script: `date` ***************** "

exit

