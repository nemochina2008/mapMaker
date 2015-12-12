read.worldmap <- function(infile="data/ne_10m_admin_0_countries_lakes",
                          countries=NULL,namefield="NAME_LONG") {
  read.regions(infile,countries,namefield)
}

read.admin1 <- function(infile="data/ne_10m_admin_1_states_provinces",
                        countries="BE",namefield="woe_name"){
  read.regions(infile,countries,namefield)
}

read.regions <- function(infile, countries,namefield){
# for world map: admin_0 and namefield=NAME_LONG
# TODO : if two namefields are given: paste(..,sep=":")
  require(maptools)
  PW <- readShapePoly(infile)
  PW <- PW[which(PW$iso_a2 %in% countries),]

  region.names <- as.character(PW[[namefield]])
  nregions <- length(region.names)

  ngon <- vapply(1:nregions,FUN=function(i) length(PW@polygons[[i]]@Polygons),FUN.VALUE=1)

  gon.names <- unlist(lapply(1:dim(PW)[1], function(i) {
             if(ngon[i]==1) region.names[i] else paste(region.names[i],1:ngon[i],sep=":")}))

  allpoly <- lapply(PW@polygons, function(x) lapply(x@Polygons, function(y) y@coords))
## allpoly is a list of lists of Nx2 matrices (not data frames)
## first flatten the list, then add NA to every row, then rbind and remove last NA
#  p1 <- do.call(c, allpoly)
#  p2 <- lapply(p1, function(x) rbind(x,c(NA,NA)))
#  p3 <- do.call(rbind,p2)
  result <- do.call(rbind, lapply(do.call(c,allpoly), function(x) rbind(x,c(NA,NA))))

  list(x=head(result[,1],-1),y=head(result[,2],-1),names=gon.names)
}
