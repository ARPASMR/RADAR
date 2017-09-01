###	converti_ll.r
#	conversione da formato geotiff a matrice dati in coordinate lat lon
#	gestione manca dato.
# analisi su frequenza su alcuni valori
#	cremonini (modificato 30/12/2011); UP modificato 07022012

suppressMessages(library(fields))
suppressMessages(library(raster))
suppressMessages(library(rgdal))

cols=400
rows=400

ndati=12 # numero di dati radar nell'ora

lev<-read.table("/home/meteo/radar_ora/level_swiss.txt",na.strings="NA")
lev<-lev$V2

args=(commandArgs(TRUE))

print(args)

infile=scan(args[1],"")
otdir=args[2]

clutter<-raster("/home/meteo/radar_ora/clutter_all.gri")

for (i in 1:length(infile)) {

	print(paste("Elaboro il raster", infile[i]))

	r<-raster(infile[i])
	projection(r)<-CRS("+proj=somerc +lat_0=+46.95241 +lon_0=+7.439583 +ellps=bessel +x_0=600000. +y_0=200000.  +k_0=1.")

#	Conversione in livelli di pioggia
    newval<-matrix(lev[(as.matrix(r) + 1)],640,710)
    r<-setValues(r,newval)

    r[r > 500]<-0
    r[r < 0]<-0
    if (length(r[r>207])>100000) {
      r[]<-0
      print(paste("File con color table GREY: ",infile[i]))
#      system(paste('/home/meteo/bin/sendEmail.pl  -s 10.10.11.26 -f u.pellegrini@arpalombardia.it -t u.pellegrini@arpalombardia.it -m "R alert" -u "GREYSCALE: "',infile[i]))   
      }

#	conversione in lat lon
    llr<-raster(nrows=rows,ncols=cols,xmn=6.7,xmx=(6.7+cols*0.013),ymn=44.0,ymx=(44.0+rows*0.009),crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0"))
    llr<-projectRaster(r,llr,method="ngb")

#	declutter con mappa clutter
    llr<-llr-clutter
    llr[llr < 0]<-0

# output
  	otfile=paste(otdir,"/",substr(infile[i],(nchar(infile[i])-40),(nchar(infile[i])-5)),sep="")
    print(otfile)
    writeRaster(llr,otfile,format="raster",overwrite=TRUE, datatype='FLT4S')

}

