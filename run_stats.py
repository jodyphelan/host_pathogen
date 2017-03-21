from  __future__ import division
import sys
from tqdm import tqdm
import subprocess
import gzip

genofile = sys.argv[1]
prefix = sys.argv[2]
af_cut = float(sys.argv[3])
i=0
j=0
temp_name = "%s.%s.temp_stats.txt" % (prefix,j)
temp_geno = prefix+".temp_geno.txt"
out = open(temp_geno,"w")
for l in tqdm(gzip.open(sys.argv[1],"rb")):
	if i==1000000:
		out.close()
		subprocess.call("Rscript process_results.r %s %s 20" % (temp_geno,temp_name),shell=True)
		j+=1
		temp_name = "%s.%s.temp_stats.txt" % (prefix,j)
		i=0
		out = open(temp_geno,"w")
	arr = l.rstrip().split()
	af = (int(arr[6])+int(arr[8])+int(arr[10]))/sum([int(x) for x in arr[5:11]])
	if af>af_cut:
		out.write(l)
		i+=1
