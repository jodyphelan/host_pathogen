library(parallel)
library(data.table)
library(scales)
library(RColorBrewer)


args = commandArgs(trailingOnly=TRUE)

if (length(args)!=2) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==2) {
  print(args)
}
infile<-paste("results/",args[1],".results",sep="")
outfile<-paste("processed_results/",args[1],".processed_results.txt",sep="")
plotfile<-paste("plots/",args[1],".png",sep="")
threads<-as.numeric(args[2])

ftest<-function(x){
	fisher.test(matrix(as.numeric(x[2:7]),nrow=2))$p.value
}

collapsed_model<-function(x,print_mat = F){
	mat<-matrix(rep(0,4),nrow=2)
	mat[1,1]<-(x[1]*2)+x[3]
	mat[1,2]<-(x[5]*2)+x[3]
	mat[2,1]<-(x[2]*2)+x[4]
	mat[2,2]<-(x[6]*2)+x[4]
	pval = 1
	if (print_mat==T){print(mat)}
	if (all(mat>5)){pval<-chisq.test(mat)$p.value}
	pval
}

hetero_model<-function(x,print_mat = F){
	mat<-matrix(rep(0,4),nrow=2)
	mat[1,1]<-x[1]+x[5]
	mat[1,2]<-x[3]
	mat[2,1]<-x[2]+x[6]
	mat[2,2]<-x[4]
	pval = 1
        if (print_mat==T){print(mat)}
	if (all(mat>5)){pval<-chisq.test(mat)$p.value}
	pval

}

dominant_model<-function(x,print_mat = F){
        mat<-matrix(rep(0,4),nrow=2)
        mat[1,1]<-x[1]
        mat[1,2]<-x[3]+x[5]
        mat[2,1]<-x[2]
        mat[2,2]<-x[4]+x[6]
	pval = 1
	if (print_mat==T){print(mat)}
	if (all(mat>5)){pval<-chisq.test(mat)$p.value}
	pval

}

additive_model<-function(x,print_mat=F){
	hum<-c(rep(0,x[1]+x[2]),rep(1,x[3]+x[4]),rep(2,x[5]+x[6]))
	tb<-c(rep(0,x[1]),rep(1,x[2]),rep(0,x[3]),rep(1,x[4]),rep(0,x[5]),rep(1,x[6]))
	table(tb,hum)
#	summary(glm(tb ~ hum))
}


test_models<-function(x){
	pvals = c()
	tryCatch(
		{
			pvals<-c(collapsed_model(x),hetero_model(x),dominant_model(x))
			c(min(pvals),match(min(pvals),pvals),0)
		},warning=function(w){
			pvals<-c(collapsed_model(x),hetero_model(x),dominant_model(x))
			c(min(pvals),match(min(pvals),pvals),1)
		}
	)
#	c(min(pvals),match(min(pvals),pvals))
}


# Calculate the number of cores
#no_cores <- detectCores() - 1
no_cores <- threads
# Initiate cluster
cl <- makeCluster(no_cores)

# Export functions
clusterExport(cl, "collapsed_model")
clusterExport(cl, "hetero_model")
clusterExport(cl, "dominant_model")



dat<-as.data.frame(fread(infile))
dat.mat<-as.matrix(dat[c(-1)])
min_pvals<-t(parApply(cl,dat.mat,1,test_models))

results<-cbind(dat,min_pvals)
colnames(results)<-c("loci","a","b","c","d","e","f","pval","model","warning")

bim<-as.data.frame(fread("host/host.bim"))

loci2rs<-function(x){strsplit(strsplit(x,"-")[[1]][1],":")[[1]][2]}
rs<-parSapply(cl,results$loci,function(x){strsplit(strsplit(x,"-")[[1]][1],":")[[1]][2]})
human_pos<-bim$V4[match(rs,bim$V2)]
mtb_pos<-parSapply(cl,results$loci,function(x){strsplit(strsplit(x,"-")[[1]][2],":")[[1]][2]})

results$mtb_pos<-as.numeric(mtb_pos)
results$human_pos<-as.numeric(human_pos)

write.table(results[results$pval<0.05,],outfile,quote=F,row.names=F,col.names=F)

#--------------------------#
#          Plots           #
#--------------------------#

res<- results[which(results$warning==0 & results$pval<1e-5),]
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

png(plotfile,1024,1024)

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
dev.off()
