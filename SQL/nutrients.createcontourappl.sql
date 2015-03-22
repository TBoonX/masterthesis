-- Function: nutrients.createcontourappl(text, text, text, text)

-- DROP FUNCTION nutrients.createcontourappl(text, text, text, text);
-- select * from nutrients.createcontourappl('107546', '10363', 'mg', 'AUTO');
CREATE OR REPLACE FUNCTION nutrients.createcontourappl(fieldid text, periodid text, el text, method text)
  RETURNS SETOF nutrients.contourtextpolygon AS
$BODY$

##=====================================================================
## Schlaggeometrie aus farm.fields
## fieldid ist id des aktuellen Schlags aller Schläge mit 
## gleicher uoid
##=====================================================================

samplesf <<- pg.spi.exec(sprintf (
"select 
  st_xmin(box2d(geom)), st_ymin(box2d(geom)), 
  st_xmax(box2d(geom)), st_ymax(box2d(geom))
from (
  Select st_transform(geom,common.find_utm_srid(st_centroid(geom))) as geom 
  from farm.fields where id = %s 
  ) as c;", fieldid))

pg.thrownotice("createcontourappl -> fieldgeom found")

##=====================================================================
## Probenpunkte aus Mapping der Proben auf Periode
##=====================================================================

samples <<- pg.spi.exec(sprintf (
"select s.id, 
  st_x(st_transform(s.geom, common.find_utm_srid(s.geom))) as x,
  st_y(st_transform(s.geom, common.find_utm_srid(s.geom))) as y,
  %s as appelement
  from nutrients.get_samplesofperiod(%s) m
  inner join nutrients.samples s on s.id = m.sampleid;", el, periodid))

pg.thrownotice("createcontourappl -> samplepoints found")

##=====================================================================
## Level der z-Diskretisierung suchen
##=====================================================================

elevels <- as.vector(pg.spi.exec(sprintf (
"select nutrients.get_applicationlevels(maxv, minv) from 
(Select max(%s) as maxv, min(%s) as minv from nutrients.samples p
inner join nutrients.get_samplesofperiod(%s) m 
on m.sampleid = p.id)x", el, el, periodid)))

pg.thrownotice("createcontourappl -> elevels found")

#save (samplesf, file=("/tmp/appsamplesf.RData"))
#save (samples, file=("/tmp/appsamples.RData"))
#save (elevels, file=("/tmp/appelevels.RData"))

library(gstat)
library(maptools)

##=====================================================================
## Bereinige samples und Schlaggeometrie
##=====================================================================
e<-na.omit(samples)
coordinates(e) <- ~x+y

f<-na.omit(samplesf)

##=====================================================================
## Grid erstellen
##=====================================================================

## Gridauflösung
reso <- 12 #resolution for the grid

## Grid erstellen
grd <- expand.grid(x=seq(from=samplesf$st_xmin-reso, to=samplesf$st_xmax+reso, by=reso), y=seq(from=samplesf$st_ymin-reso, to=samplesf$st_ymax+reso, by=reso))
coordinates(grd) <- ~ x+y
gridded(grd) <- TRUE
element<-"appelement"

##=====================================================================
## Kriging entsprechend Vorgabe-Methode
##=====================================================================

## Kriging gewichtet mit reziprokem Abstand
if (method =="INVDIST"){
g <- gstat(id=element , formula=appelement ~ 1, data=e)
krig <- predict(g, model=v.fit, newdata=grd)
}

## Lineares Fitmodell:
## mittlerer Abstand als Init für Fit 
if (method =="LIN"){
g <- gstat(id=element , formula=appelement ~ 1, data=e)
vari <- variogram(g)
mdist <- mean(vari$dist)
v.fit <- fit.variogram(vari, model=mo <- vgm(model='Lin', mdist))
g <- gstat(g, id=element, model=v.fit)
krig <- predict(g, model=v.fit, newdata=grd)
}

## Lineares Fitmodell mit Nugget 
if (method=="LIN-NUG"){
g <- gstat(id=element , formula=appelement ~ 1, data=e)
v <- variogram(g)
mdist <- mean(v$dist)
v.fit <- fit.variogram(v, model=vgm(model='Lin', nugget=TRUE))
g <- gstat(g, id=element, model=v.fit)
krig <- predict(g, model=v.fit, newdata=grd)
}

if (method=="AUTO"){
library(automap)
akrig <- autoKrige(appelement  ~ 1,e,grd)
krig<-akrig[[1]]
}

#testlevel <- c(0, 1000,2000,3000,4000,5000,6000,7000) 
krig.levels <- elevels[[1]]
#in vector wandeln
list <- contourLines(as.image.SpatialGridDataFrame(as(krig,"SpatialGridDataFrame")),levels=elevels[[1]])
#in linien wandeln
line = array()

for (i in 1:length(list)) {
	linestr=list[[i]]
	curline = "("
	for (j in 1:length(linestr$x)) {	
             curline = sprintf("%s %.2f %.2f,",curline,linestr$x[[j]],linestr$y[[j]])
        }
  curline =  paste(substr(curline, 1, nchar(curline)-1),")")
     #curline = sprintf("%s %.2f %.2f)",curline,linestr$x[[length(linestr$x)]],linestr$y[[length(linestr$x)]])
	 line[[i]] <- curline
     #level_[[i]] <- list[[i]]$level
}

curline = "MULTILINESTRING("
for (k in 1:length(line)) {
l = paste(line[k], ",")
curline = paste(curline,l)
}

curline = paste(substr(curline, 1, nchar(curline)-1),")")
pglabelpoints <<- pg.spi.exec(sprintf (
"Select (i).polygon, (i).cx, (i).cy from 
  (Select nutrients.getfieldlabelpoints('%s', %s) as i) x",curline,fieldid))
#save (pglabelpoints, file=("/tmp/labelpoints.RData"))

S <- SpatialPoints(cbind(pglabelpoints[[2]],pglabelpoints[[3]]))
pglabelpoints[[4]] <- over(S, krig)[1]

#save (pglabelpoints, file=("/tmp/labelpoints2.RData"))
#return pglabelpoints[[1]][1]
return (data.frame(pglabelpoints[[4]], pglabelpoints[[1]]))
 
$BODY$
  LANGUAGE plr VOLATILE
  COST 100
  ROWS 100;
ALTER FUNCTION nutrients.createcontourappl(text, text, text, text)
  OWNER TO dboperator;
COMMENT ON FUNCTION nutrients.createcontourappl(text, text, text, text) IS 'R-Kriging für Streukarten';
