args = commandArgs(trailingOnly=TRUE)

if (length(args)!=1) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==1) {
  print(args)
}


