#!/usr/bin/Rscript

library(classInt)
library(maptools)
library(raster)
library(sp)
library(gridExtra)
library(rgeos)
library(rgdal)

args=(commandArgs(TRUE))
print(args)
infile=args[1]
data_evento=args[2]

TEMP_DIR<-Sys.getenv("TMP_DIR")
print(TEMP_DIR)

SHAPE_DIR<-Sys.getenv("GASHP")
print(SHAPE_DIR)

matrice_grads<-t(matrix(readBin(infile,"double",160000,4),400,400))
llr<-raster(nrows=400,ncols=400,xmn=6.7,xmx=(6.7+400*0.013),ymn=44.0,ymx=(44.0+400*0.009),crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0"))
llr<-setValues(llr,matrice_grads)
italia <- readShapePoly("/home/meteo/grads_shapefile/ITA_adm3")
regioni <- readShapePoly("/home/meteo/grads_shapefile/ITA_adm2")
vda<-regioni[regioni@data$NAME_1=="Valle d'Aosta",]

#RADcols <- c(white="#FFFFFF",grey="#C8C8C8",darkgrey="#9B7D96", blue="#0064FF",green="#058C2D",light_green="#05FF05",yellow="#FFFF00",orange="#FFC800",darkorange="#FF7D00",red="#FF1900",purple="#AF00DC",dark_purple="#8200DC",violet="#6400DC")
#labelat = c(0,0.5,1,5,10,20,40,60,80,100,150,200,250,350)
#labeltext = paste("",c("","","",5,10,20,40,60,80,100,150,200,250,350)) 

RADcols <- c("white","cadetblue1","steelblue1","green","yellow","orange","red","magenta","orangered4","purple")
labelat = c(0,1,5,10,20,40,60,80,100,200,300)
labeltext = paste("",c("","",5,10,20,40,60,80,100,200,300))
#14 intervalli, 13 colorii

prov="Valle d'Aosta"

test_prov<-italia[italia$NAME_1==prov,]
estraz<-extract(llr,test_prov)

max<-lapply(estraz,max)
max<-unlist(max)
max[max<0]<-0
test_prov$massimo<-max
max <- round(test_prov@data$massimo,1)

mean=lapply(estraz,mean)
mean<-unlist(mean)
mean[mean<0]<-0
test_prov$media<-mean
mean <- round(test_prov@data$media,1)

qu50=lapply(estraz,quantile,probs=c(.5))
qu75=lapply(estraz,quantile,probs=c(.75))
qu90=lapply(estraz,quantile,probs=c(.9))
qu98=lapply(estraz,quantile,probs=c(.98))
qu50<-unlist(qu50)
qu75<-unlist(qu75)
qu90<-unlist(qu90)
qu98<-unlist(qu98)
test_prov$qu50<-qu50
test_prov$qu75<-qu75
test_prov$qu90<-qu90
test_prov$qu98<-qu98
qu50 <- round(test_prov@data$qu50,1)
qu75 <- round(test_prov@data$qu75,1)
qu90 <- round(test_prov@data$qu90,1)
qu98 <- round(test_prov@data$qu98,1)

comuni<-test_prov@data$NAME_3
datone<-data.frame(comuni,max,mean,coordinates(test_prov),qu50,qu75,qu90,qu98)
sort.datone.max<-datone[order(-datone$max),]
sort.datone.max<-data.frame("Index"=c(1:nrow(sort.datone.max)),sort.datone.max)
sort.datone.mean<-datone[order(-datone$mean),]
sort.datone.mean<-data.frame("Index"=c(1:nrow(sort.datone.mean)),sort.datone.mean)

print.max<-data.matrix(sort.datone.max[5:6])[1:5,1:2]
rownames(print.max)<-NULL
colnames(print.max)<-NULL
print.mean<-data.matrix(sort.datone.mean[5:6])[1:5,1:2]
rownames(print.mean)<-NULL
colnames(print.mean)<-NULL

txt.max<-list("sp.text", print.max,sort.datone.max$Index[1:5],cex=1,fontface = "bold",which=2 )
txt.mean<-list("sp.text", print.mean,sort.datone.mean$Index[1:5],cex=1,fontface = "bold",which=1 )
titolo<-paste(prov," precipitazione cumulata giornaliera in data ",data_evento,sep="")
#png_file<-paste(prov,"_",data_evento,".png",sep="")
png_file<-paste("vda_",data_evento,".png",sep="")

#stampa
#png(file=png_file,width=2048,height=1536)
png(file=png_file,width=1024,height=1024)

p1<-spplot(test_prov,c("media","massimo"),cex=6,xlab = NULL, ylab = NULL,as.table=TRUE,strip=strip.custom(par.strip.text=list(cex=1.5)),col="grey",col.regions=RADcols,at=labelat,par.settings =list(axis.line = list(col='grey'),fontsize=list(text=16.4)),main=list(label=titolo,cex=1.6),sp.layout = list(txt.max,txt.mean),colorkey=list(width=0.8,space="left",  tick.number=1,labels=list(at=labelat,labels=labeltext,cex=1)))

p2<-tableGrob(sort.datone.max[1:5,c('Index','comuni','qu90','qu98','max')],show.rownames=F,gpar.coretext = gpar(fontsize=20),gpar.coltext = gpar(fontsize=20, fontface = "bold"),gpar.rowtext = gpar(fontsize=20, fontface = "bold"))

p3<-tableGrob(sort.datone.mean[1:5,c('Index','comuni','mean','qu50','qu75')],show.rownames=F,gpar.coretext = gpar(fontsize=20),gpar.coltext = gpar(fontsize=20, fontface = "bold"),gpar.rowtext = gpar(fontsize=20, fontface = "bold"))

tabella<-arrangeGrob(p3,p2,ncol=2)
grid.arrange(p1,tabella,heights=c(3/4,1/4),nrow=2)
dev.off()

# plot valori radar giornalieri
regioni <- readOGR("/home/meteo/grads_shapefile/","ITA_adm2")
aosta<-regioni[regioni$NAME_1 =="Valle d'Aosta",]
fiumi<-readOGR("/home/meteo/grads_shapefile/","ITA_water_lines_dcw")
rivers.cut <- gIntersection(fiumi, aosta)

area_VDA_est<-extent(6.7,8.2,45.4,46.1)
area_VDA<-crop(llr,area_VDA_est)

png_file<-paste("vdadaily_",data_evento,".png",sep="")
#png(file=png_file,width=2048,height=1536)
png(file=png_file,width=1024,height=1024)

lema<-read.table(paste(TEMP_DIR,"/","lema.txt",sep=""))
dole<-read.table(paste(TEMP_DIR,"/","dole.txt",sep=""))
albis<-read.table(paste(TEMP_DIR,"/","albis.txt",sep=""))
plaine<-read.table(paste(TEMP_DIR,"/","plaine.txt",sep=""))

#dole<-read.table("/home/meteo/radar_giorno/tmp/dole.txt")
#albis<-read.table("/home/meteo/radar_giorno/tmp/albis.txt")
#plaine<-read.table("/home/meteo/radar_giorno/tmp/plaine.txt")

#plot(area_VDA,breaks=c(0.1,5,10,20,40,60,80,100,200),col=c("cadetblue1","steelblue1","green","yellow","orange","red","magenta","orangered4"),main=paste(c("RADAR 24h cumulated precipitation on "),data_evento))
plot(area_VDA,breaks=c(1,5,10,20,40,60,80,100,200,300),col=c("cadetblue1","steelblue1","green","yellow","orange","red","magenta","orangered4","purple"),main=paste(c("RADAR 24h cumulated precipitation on "),data_evento))
plot(regioni,add=T)
plot(rivers.cut,col="blue",add=T)
text(6.82,45.24,paste("Plaine: ",c(plaine)))
text(6.82,45.27,paste("Lema: ",c(lema)))
text(6.82,45.3,paste("Dole: ",c(dole)))
text(6.82,45.33,paste("Albis: ",c(albis)))

dev.off()

