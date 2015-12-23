## EXAMPLE SCRIPT:
## This is the script that generates the new 'world' database
## in the maps package.
## Only the polygon names are different.

library(mapMaker)
infile <- "~/code/NaturalEarth/v3.1.0/data/ne_50m_admin_0_countries_lakes"
outfile <- "~/code/NaturalEarth/build.world50/w50"
Sys.setenv("MYMAPS"=paste0(dirname(outfile),"/"))
assign(paste0(basename(outfile),"MapEnv"),"MYMAPS")

######################

ww <- map.make(read.worldmap(infile))
############################################################
### Antarctica: remove fake points & don't close polygon ###
############################################################
find.antarctica <- function(ww){
  i <- which(ww$y < -85)[1]
  which(ww$line$begin <= i & ww$line$end >= i)
}

p121 <- get.line(ww,121)
p121 <- p121[c(2070:2805,2:1804),]
ww <- line.change(ww,121,p121)

################################
### Recombine split polygons ###
################################

w1 <- unique(unlist(lapply(which(ww$x < -179.99),function(i) which.line(ww, i))))
e1 <- unique(unlist(lapply(which(ww$x >  179.99),function(i) which.line(ww, i))))
# print(ww$names[w1])
# print(ww$names[e1])
w1 <- w1[-1]  # not 121=Antarctica
e1 <- e1[-1]

for(l in w1) assign(paste("w",l,sep=""),get.line(ww,l))
for(l in e1) assign(paste("e",l,sep=""),get.line(ww,l))

## MANUAL: combine polygons, remove superfluous polygon from names list & data
## for both Fiji and Russia: most logical to move west part by +360

# Fiji: line/poly 537:557
# (551=552)-(553=554)-(555 = 556)
w552$x <- w552$x + 360
w554$x <- w554$x + 360
w556$x <- w556$x + 360

p551 <- rbind(e551[1:5,],w552[7:11,],e551[1,])
ww <- line.change(ww,551,p551)

p553 <- rbind(e553[1:4,],w554[4:7,],e553[1,])
ww <- line.change(ww,553,p553)

p555 <- rbind(w556[2,],e555[2:56,],w556[c(5:7,2),])
ww <- line.change(ww,555,p555)

# Russia: 1285=1328(main), 1296 = 1294
w1285$x <- w1285$x + 360
w1296$x <- w1296$x + 360

p1294 <- rbind(e1294[1:11,],w1296[c(23:31,2:20),],e1294[14:17,]) 
ww <- line.change(ww,1294,p1294)

p1328 <- rbind(e1328[1:633,],w1285[c(337:338,2:321),],e1328[636:4599,])
ww <- line.change(ww,1328,p1328)

# now remove superfluous polygons
remove.line.gon <- function(ww,i){
# this  assumes every lines is a polygon 
# or just run gon.remove & line.remove
  ww$x <- c(head(ww$x,ww$line$begin[i]-1),tail(ww$x,-(ww$line$end[i]+1)))
  ww$y <- c(head(ww$y,ww$line$begin[i]-1),tail(ww$y,-(ww$line$end[i]+1)))
  ww$names <- ww$names[-i]
  ww$line <- line.parse(ww)
  ww$gon <- gon.parse(ww)
}

for (i in rev(sort(w1))) ww <- remove.line.gon(ww,i)

#############################
### FIX BUGS in w50 data: ###
#############################

# (tracked by looking for line$length==2)
# some of these may not be actual bugs
# The China/India border is very contested
# but for 'maps' I need to have lines that fit exactly.
# I don't want 'no-one's land' because it screws up internal=FALSE plots.`

# BE/NL border bug (Nl is now line 1074, not 1077 because 3 polygons were removed)
p187 <- get.line(ww,187) #be
p1074 <- get.line(ww,1074)
p187[29:30,] <- p1074[120:119,]
p1074 <- p1074[-121,]
ww <- line.change(ww, 187, p187)
ww <- line.change(ww, 1074, p1074)

# AF/IR : Iran has 1 extra point in boundary (remove, or add to Afghanistan?)
p859 <- get.line(ww, 859)
p859 <- p859[-235,]
ww <- line.change(ww, 859, p859)

# China/India : many errors
# maybe easier to correct by pasting the whole border from one to the other
p442 <- get.line(ww,442)
p851 <- get.line(ww,851)
p851 <- rbind(p442[1694:1576,],p851[51:1287,])
ww <- line.change(ww, 851, p851)

# Indonesia:89/Papua New G
p792 <- get.line(ww,792)
p1209 <- get.line(ww,1209)
p1209 <- p1209[-(278:279),]
ww <- line.change(ww, 1209, p1209)

# create line database
ww0 <- ww
ww <- map.gon2line(ww0)
ww1 <- ww

#######################################################
### split meridian crossings (necessary for world2) ###
#######################################################

# insert break points at 0 (for world 2)
i <- which(head(ww$x,-1) * tail(ww$x,-1) < 0)
xi <- rep(0,length(i))
yi <- ww$y[i] + (ww$y[(i+1)]-ww$y[i])/(ww$x[(i+1)]-ww$x[i]) * (xi-ww$x[i])

ww$x <- insert.points(ww$x, i+1, 0)
ww$y <- insert.points(ww$y, i+1, yi)
ww$line <- line.parse(ww)

# split lines at 0
splits <- which(ww$x==0)
for (i in rev(sort(splits))) ww <- line.split(ww, i)

######################
### export to file ###
######################
ww <- map.LR(ww)
map.export.bin(ww, outfile)
map.export.ascii(ww, outfile, ndec=8)