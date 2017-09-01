###	stat_radar.r

suppressMessages(library(raster))
suppressMessages(library(maptools))

args=(commandArgs(TRUE))
print(args)
infile=args[1]

outdir<-Sys.getenv("LOCKDIR")
shape_dir<-Sys.getenv("GASHP")
print(outdir)
print(shape_dir)

outfile=paste(outdir,"/stat_radar.txt",sep="")
print(outfile)

#	matrice trasposta
matrice_grads=t(matrix(readBin(infile,"double",160000,4),400,400))

#	definisco raster
llr<-raster(nrows=400,ncols=400,xmn=6.7,xmx=(6.7+400*0.013),ymn=44.0,ymx=(44.0+400*0.009),crs=CRS("+proj=longlat +ellps=WGS84+datum=WGS84 +no_defs +towgs84=0,0,0"))

#	metto nel raster i valori della matrice
llr=setValues(llr,matrice_grads)

#	Lettura di parte degli shapefiles
#	maptools gestisce il subsettings

italia1=readShapeSpatial(paste(shape_dir,"/ITA_adm1",sep=""))

#importante la virgola!
lombardia1=italia1[italia1$NAME_1=="Lombardia",]	
v_lombardia1=extract(llr,lombardia1)
q_v_lombardia1=lapply(v_lombardia1,quantile,probs=c(.0,.25,.50,.75,.9,1))
print(q_v_lombardia1)

#italia=readShapeSpatial("/home/meteo/grads_shapefile/ITA_adm2")
italia=readShapeSpatial(paste(shape_dir,"/ITA_adm2",sep=""))

#attributes(italia@data)	#per vedere checazzo ci sta nello shapefile
# subsetting
#lombardia.italia=italia[italia$NAME_1=="Lombardia",]

#liguria=italia[italia$NAME_1=="Liguria",]	#importante la virgola!
#plot(liguria)

#lombardia=italia[italia$NAME_1=="Lombardia",]	#importante la virgola!
#v_lombardia=extract(llr,lombardia)
#q_v_lombardia=lapply(v_lombardia,quantile,probs=c(.0,.25,.50,.75,.9,1))
#print(q_v_lombardia)

bg=italia[italia$NAME_2=="Bergamo",]
bs=italia[italia$NAME_2=="Brescia",]
co=italia[italia$NAME_2=="Como",]
cr=italia[italia$NAME_2=="Cremona",]
lc=italia[italia$NAME_2=="Lecco",]
lo=italia[italia$NAME_2=="Lodi",]
mn=italia[italia$NAME_2=="Mantua",]
mi=italia[italia$NAME_2=="Milano",]
mb=italia[italia$NAME_2=="Monza and Brianza",]
pv=italia[italia$NAME_2=="Pavia",]
so=italia[italia$NAME_2=="Sondrio",]
va=italia[italia$NAME_2=="Varese",]

#	clipv_liguria=extract(liguria,llr) dei valori del raster sugli shapefile
v_bg=extract(llr,bg)
v_bs=extract(llr,bs)
v_co=extract(llr,co)
v_cr=extract(llr,cr)
v_lc=extract(llr,lc)
v_lo=extract(llr,lo)
v_mn=extract(llr,mn)
v_mi=extract(llr,mi)
v_mb=extract(llr,mb)
v_pv=extract(llr,pv)
v_so=extract(llr,so)
v_va=extract(llr,va)


q_v_bg=lapply(v_bg,quantile,probs=c(.5,.9,1))
q_v_bs=lapply(v_bs,quantile,probs=c(.5,.9,1))
q_v_co=lapply(v_co,quantile,probs=c(.5,.9,1))
q_v_cr=lapply(v_cr,quantile,probs=c(.5,.9,1))
q_v_lc=lapply(v_lc,quantile,probs=c(.5,.9,1))
q_v_lo=lapply(v_lo,quantile,probs=c(.5,.9,1))
q_v_mn=lapply(v_mn,quantile,probs=c(.5,.9,1))
q_v_mi=lapply(v_mi,quantile,probs=c(.5,.9,1))
q_v_mb=lapply(v_mb,quantile,probs=c(.5,.9,1))
q_v_pv=lapply(v_pv,quantile,probs=c(.5,.9,1))
q_v_so=lapply(v_so,quantile,probs=c(.5,.9,1))
q_v_va=lapply(v_va,quantile,probs=c(.5,.9,1))

cat("bg ",file=outfile)
lapply(q_v_bg, write, outfile, append=TRUE, ncolumns=1000)

cat("bs ",file=outfile,append=TRUE)
lapply(q_v_bs, write, outfile, append=TRUE, ncolumns=1000)

cat("co ",file=outfile,append=TRUE)
lapply(q_v_co, write, outfile, append=TRUE, ncolumns=1000)

cat("cr ",file=outfile,append=TRUE)
lapply(q_v_cr, write, outfile, append=TRUE, ncolumns=1000)

cat("lc ",file=outfile,append=TRUE)
lapply(q_v_lc, write, outfile, append=TRUE, ncolumns=1000)

cat("lo ",file=outfile,append=TRUE)
lapply(q_v_lo, write, outfile, append=TRUE, ncolumns=1000)

cat("mn ",file=outfile,append=TRUE)
lapply(q_v_mn, write, outfile, append=TRUE, ncolumns=1000)

cat("mi ",file=outfile,append=TRUE)
lapply(q_v_mi, write, outfile, append=TRUE, ncolumns=1000)

cat("mb ",file=outfile,append=TRUE)
lapply(q_v_mb, write, outfile, append=TRUE, ncolumns=1000)

cat("pv ",file=outfile,append=TRUE)
lapply(q_v_pv, write, outfile, append=TRUE, ncolumns=1000)

cat("so ",file=outfile,append=TRUE)
lapply(q_v_so, write, outfile, append=TRUE, ncolumns=1000)

cat("va ",file=outfile,append=TRUE)
lapply(q_v_va, write, outfile, append=TRUE, ncolumns=1000)

