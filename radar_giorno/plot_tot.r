
library(classInt)
library(maptools)
library(raster)
library(sp)
library(gridExtra)
args=(commandArgs(TRUE))
print(args)
infile=args[1]
data_evento=args[2]
png_file<-paste("vda_",data_evento,".png",sep="")

matrice_grads<-t(matrix(readBin(infile,"double",160000,4),400,400))
llr<-raster(nrows=400,ncols=400,xmn=6.7,xmx=(6.7+400*0.013),ymn=44.0,ymx=(44.0+400*0.009),crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0"))
llr<-setValues(llr,matrice_grads)

#regioni <- readShapePoly("/home/meteo/grads_shapefile/ITA_adm2")
regioni <- readOGR("/home/meteo/grads_shapefile/","ITA_adm2")
aosta<-regioni[regioni$NAME_1 =="Valle d'Aosta",]
fiumi<-readOGR("/home/meteo/grads_shapefile/","ITA_water_lines_dcw")
rivers.cut <- gIntersection(fiumi, aosta)

area_VDA_est<-extent(6.7,8.2,45.4,46.1)
area_VDA<-crop(llr,area_VDA_est)
png(file=png_file,width=1300,height=700)

plot(area_VDA,breaks=c(0.1,5,10,20,40,60,80,100,200),col=c("cadetblue1","steelblue1","green","yellow","orange","red","magenta","orangered4"),main=paste(c("RADAR 24h cumulated precipitation on "),data_evento))
plot(regioni,add=T)
plot(rivers.cut,col="blue",add=T)

#col=c("grey","beige","bisque2","green","yellow","orange","red","violet","purple"
#col=c("steelblue1","cadetblue1","green","yellow","orange","red","violet","purple")
#"steelblue1"
#"cadetblue1"

#spplot(area_VDA,at=c(0.1,5,10,20,30,40,50,80,120,160),col.regions=c("grey","beige","bisque2","green","yellow","orange","red","violet","purple"))
