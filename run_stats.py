from  __future__ import division
import sys
from tqdm import tqdm
import subprocess
import gzip

genofile = sys.argv[1]
prefix = sys.argv[2]
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
	i+=1
	out.write(l)

out.close()
subprocess.call("Rscript process_results.r %s %s 20" % (temp_geno,temp_name),shell=True)

subprocess.call("cat %s.*.temp_stats.txt > %s.stats.txt" % (prefix,prefix),shell=True)
subprocess.call("rm %s.*.temp_stats.txt"% (prefix),shell=True)
