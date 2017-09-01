library(classInt)
library(maptools)
library(raster)
library(sp)
library(gridExtra)

args=(commandArgs(TRUE))
print(args)
infile=args[1]

matrice_grads<-t(matrix(readBin(infile,"double",160000,4),400,400))
llr<-raster(nrows=400,ncols=400,xmn=6.7,xmx=(6.7+400*0.013),ymn=44.0,ymx=(44.0+400*0.009),crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0"))
llr<-setValues(llr,matrice_grads)
italia <- readShapePoly("/home/meteo/grads_shapefile/ITA_adm3")
regioni <- readShapePoly("/home/meteo/grads_shapefile/ITA_adm2")
lombardia<-regioni[regioni@data$NAME_1=="Lombardia",]
province<-lombardia$NAME_2

RADcols <- c(white="#FFFFFF",grey="#C8C8C8",darkgrey="#9B7D96", blue="#0064FF",green="#058C2D",light_green="#05FF05",yellow="#FFFF00",orange="#FFC800",darkorange="#FF7D00",red="#FF1900",purple="#AF00DC",dark_purple="#8200DC",violet="#6400DC")
labelat = c(0,0.5,1,5,10,20,40,60,80,100,150,200,250,350)
labeltext = paste("",c("","","",5,10,20,40,60,80,100,150,200,250,350)) 

for(prov in province) {
  print(prov)
  test_prov<-italia[italia$NAME_2==prov,]
  estraz<-extract(llr,test_prov)

  max<-lapply(estraz,max)
  max<-unlist(max)
  max[max<0]<-0
  test_prov$massimo<-max
  max <- round(test_prov@data$massimo,0)

  mean=lapply(estraz,mean)
  mean<-unlist(mean)
  mean[mean<0]<-0
  test_prov$media<-mean
  mean <- round(test_prov@data$media,0)

  quantile50=lapply(estraz,quantile,probs=c(.5))
  quantile75=lapply(estraz,quantile,probs=c(.75))
  quantile90=lapply(estraz,quantile,probs=c(.9))
  quantile98=lapply(estraz,quantile,probs=c(.98))
  quantile50<-unlist(quantile50)
  quantile75<-unlist(quantile75)
  quantile90<-unlist(quantile90)
  quantile98<-unlist(quantile98)
  test_prov$quantile50<-quantile50
  test_prov$quantile75<-quantile75
  test_prov$quantile90<-quantile90
  test_prov$quantile98<-quantile98
  quantile50 <- round(test_prov@data$quantile50,0)
  quantile75 <- round(test_prov@data$quantile75,0)
  quantile90 <- round(test_prov@data$quantile90,0)
  quantile98 <- round(test_prov@data$quantile98,0)

  comuni<-test_prov@data$NAME_3
  datone<-data.frame(comuni,max,mean,coordinates(test_prov),quantile50,quantile75,quantile90,quantile98)
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
  titolo<-paste("Provincia di ",prov,sep="")
  png_file<-paste(prov,".png",sep="")

#stampa
  png(file=png_file,width=1300,height=700)
  p1<-spplot(test_prov,c("media","massimo"),cex=6,xlab = NULL, ylab = NULL,as.table=TRUE,strip=strip.custom(par.strip.text=list(cex=1.5)),col="grey",col.regions=RADcols,at=labelat,par.settings =list(axis.line = list(col='grey'),fontsize=list(text=8.4)),main=list(label=titolo,cex=1.6),sp.layout = list(txt.max,txt.mean),colorkey=list(width=0.8,space="left",  tick.number=1,labels=list(at=labelat,labels=labeltext,cex=1)))

  p2<-tableGrob(sort.datone.max[1:5,c('Index','comuni','quantile90','quantile98','max')],show.rownames=F,gpar.coretext = gpar(fontsize=12),gpar.coltext = gpar(fontsize=12, fontface = "bold"),gpar.rowtext = gpar(fontsize=12, fontface = "bold"))

  p3<-tableGrob(sort.datone.mean[1:5,c('Index','comuni','mean','quantile50','quantile75')],show.rownames=F,gpar.coretext = gpar(fontsize=12),gpar.coltext = gpar(fontsize=12, fontface = "bold"),gpar.rowtext = gpar(fontsize=12, fontface = "bold"))

  tabella<-arrangeGrob(p3,p2,ncol=2)
  grid.arrange(p1,tabella,heights=c(3/4,1/4),nrow=2)
  dev.off()
}
