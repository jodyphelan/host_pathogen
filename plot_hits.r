library(scales)

dat<-read.table("hits.pos.txt")

xlims<-c(0,101)
ylims<-c(0.9,2.1)
human_max<-max(c(dat$V1,dat$V1))
mtb_max<-max(c(dat$V2,dat$V2))
human_sc<-scale(human_max,F,100)
mtb_sc<-scale(mtb_max,F,100)
starts<-c(0,0)
ends<-c(100,100)
n<-dim(dat)[1]
plot(0,yaxt="n",,xaxt="n",type="n",xlim=xlims,ylim=ylims,ylab="Genomes",xlab="Genome position (Mb)")
segments(starts,c(1,2),ends,c(1,2),lwd=2)
segments(dat$V1/human_sc,rep(2,n),dat$V2/mtb_sc,rep(1,n),col=alpha("blue",0.3))
segments(28124449/human_sc,2,33601316/human_sc,2,col="red",lwd=3)
axis(side=3,at=seq(0,human_max,20000000)/human_sc,labels=seq(0,human_max,20000000)/1000000)
axis(side=1,at=seq(0,mtb_max,1000000)/mtb_sc,labels=seq(0,mtb_max,1000000)/1000000)
