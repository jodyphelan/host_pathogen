library(data.table)
library(scales)
library(RColorBrewer)


args = commandArgs(trailingOnly=TRUE)
if (length(args)!=2) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==2) {
  print(args)
}
infile<-paste("processed_results/",args[1],".processed_results.txt",sep="")
plotfile<-paste("plots/",args[1],"_",args[2],".png",sep="")
min_pval<-as.numeric(args[2])



results<-as.data.frame(fread(infile))
colnames(results)<-c("loci","a","b","c","d","e","f","pval","model","warning","mtb_pos","human_pos")

res<- results[which(results$warning==0 & results$pval<min_pval),]
ann<-as.data.frame(fread("~/thaiGWAS/imputed_vcf/ann/snps.db"))


xlims<-c(0,101)
ylims<-c(0.9,3.1)
human_max<-max(res$human_pos)
mtb_max<-max(res$mtb_pos)
human_sc<-scale(human_max,F,100)
mtb_sc<-scale(mtb_max,F,100)
starts<-c(0,0)
ends<-c(100,100)
n<-dim(res)[1]
floor_pval<-floor(min(-log10(res$pval)))
pval_sc<-scale(max(-log10(res$pval))-floor_pval,F,1)

#linecols <- rev(heat.colors(10))
linecols <- colorRampPalette(c("lightblue","darkblue"))(10)
#linecols <- colorRampPalette(c("salmon","darkred"))(10)

seg_cols <-  linecols[ceiling((-log10(res$pval)-floor_pval)/pval_sc*10)]


doPlot<-function(){
	plot(0,yaxt="n",,xaxt="n",type="n",xlim=xlims,ylim=ylims,ylab="",xlab="")
	segments(starts,c(1,2),ends,c(1,2),lwd=2)
	segments(res$human_pos/human_sc,rep(2,n),res$mtb_pos/mtb_sc,rep(1,n),col=alpha(seg_cols,ceiling((-log10(res$pval)-floor_pval)/pval_sc)))
	
	######## HLA #########
	#hla<-subset(res, human_pos>28124449 & human_pos<33601316)
	#segments(hla$human_pos/human_sc,rep(2,n),hla$mtb_pos/mtb_sc,rep(1,n),col=alpha("red",0.3))
	#segments(28124449/human_sc,2,33601316/human_sc,2,col="red",lwd=3)
	
	axis(side=3,at=seq(0,human_max,20000000)/human_sc,labels=seq(0,human_max,20000000)/1000000)
	axis(side=1,at=seq(0,mtb_max,1000000)/mtb_sc,labels=seq(0,mtb_max,1000000)/1000000)
	points((res$human_pos/human_sc),(-log10(res$pval)/pval_sc)-(floor_pval/pval_sc)+2,pch=20,col=alpha("black",0.6))
	axis(side=2,at=((floor_pval:(floor_pval+10))/pval_sc) - (floor_pval/pval_sc) +2,labels=floor_pval:(floor_pval+10))
	mtext("-log10(pval)",side=2,line=3,at=2.5)
	mtext("Human",side=2,line=3,at=2)
	mtext("Mtb",side=2,line=3,at=1)
	mtext("Human Genome Position (Mb)", side=3,line=2,at=50)
	mtext("Mtb Position (Mb)", side=1,line=3,at=50)
}
x11()
doPlot()


geney<-tapply(-log10(res$pval),ann$V4[match(res$human_pos,ann$V2)],max)
genex<-ann$V2[match(names(geney),ann$V4)]
new_pos<-list(x=as.numeric(c()),y=as.numeric(c()))
for (i in 1:length(geney)){
	points((genex[i]/human_sc),((as.numeric(geney)[i]/pval_sc)-(floor_pval/pval_sc)+2),col="red",pch=20)
	loc<-locator(1)
	points((genex[i]/human_sc),((as.numeric(geney)[i]/pval_sc)-(floor_pval/pval_sc)+2),col="black",pch=20)
	points(loc$x,loc$y,col="blue",pch=20,cex=2)
	new_pos$x<-c(new_pos$x,loc$x)
	new_pos$y<-c(new_pos$y,loc$y)
}

png(plotfile,1024,1024)
doPlot()
text(new_pos$x,new_pos$y,labels=names(geney))
dev.off()
