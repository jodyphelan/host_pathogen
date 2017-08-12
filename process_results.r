library(parallel)
library(data.table)


args = commandArgs(trailingOnly=TRUE)

if (length(args)!=3) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} 
infile<-args[1]
outfile<-args[2]
threads<-as.numeric(args[3])


perform_tests<-function(x,print_mat=F){
	hum<-c(rep(0,x[1]+x[2]),rep(1,x[3]+x[4]),rep(2,x[5]+x[6]))
	tb<-c(rep(0,x[1]),rep(1,x[2]),rep(0,x[3]),rep(1,x[4]),rep(0,x[5]),rep(1,x[6]))
	### aditive model ###
	add_pval<-anova(glm(tb ~ hum,family="binomial"),test = "Chisq")[2,5]
	### dominant model ###
	dom_pval<-anova(glm(tb ~ I(hum==1|hum==2),family="binomial"),test = "Chisq")[2,5]
	### recessive model ###
	rec_pval<-anova(glm(tb ~ I(hum==2),family="binomial"),test = "Chisq")[2,5]
	### heterozygous model ###
	het_pval<-anova(glm(tb ~ I(hum==1),family="binomial"),test = "Chisq")[2,5]
	### general model ###
	gen_pval<-anova(glm(tb ~ as.factor(hum),family="binomial"),test = "Chisq")[2,5]
	c(add_pval,dom_pval,rec_pval,het_pval,gen_pval)
}



# Calculate the number of cores
#no_cores <- detectCores() - 1
no_cores <- threads
# Initiate cluster
cl <- makeCluster(no_cores)

# Export functions
clusterExport(cl, "perform_tests")

# Read data
dat<-as.data.frame(fread(infile))
dat.mat<-as.matrix(dat[-c(1:2)])
pvals<-t(parApply(cl,dat.mat,1,perform_tests))

results<-cbind(dat,pvals)
colnames(results)<-c("host_id","pathogen_id","a","b","c","d","e","f","add_pval","dom_pval","rec_pval","het_pval","gen_pval")
	
write.table(results,outfile,quote=F,row.names=F,col.names=F)

