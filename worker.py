#! /home/jody/software/anaconda2/bin/python
from __future__ import division
import sys
import tools
from collections import defaultdict 


script,h_prefix,p_mat,outfile,pid,h_start_idx,h_stop_idx = sys.argv


p_dict = defaultdict(dict)
h_dict = defaultdict(dict)
h_samples = [x.rstrip().split()[1] for x in open(h_prefix+".tfam").readlines()]
h_start_idx = int(h_start_idx)
h_stop_idx = int(h_stop_idx)

id2pos = {}
with open(h_prefix+".tped") as f:
	for i,l in enumerate(f):
		if i>=h_start_idx and i<=h_stop_idx:
			temp = l.rstrip().split()
			recoded = tools.recode_plink("".join(temp[4:]))
			h_dict[temp[0]][temp[1]] = recoded
			id2pos[temp[1]] = temp[3]

with open(p_mat) as f:
	header = f.readline().rstrip().split()
	idx = []
	for x in h_samples:
		idx.append(header.index(x))
	for l in f:
		temp = l.rstrip().split()
		if tools.get_af("".join(temp[5:]))*len(temp[5:])<5:
			continue
		p_dict[temp[0]][temp[1]] = "".join(temp[5:])


p_snps = 0
for p_chrom in p_dict:
	for p_pos in p_dict[p_chrom]:
		p_snps+=1
h_snps = 0
for h_chrom in h_dict:
	for h_id in h_dict[h_chrom]:
		h_snps+=1
open(outfile+".combinations."+pid,"w").write("%s\n" % (p_snps*h_snps))

out = open(outfile+".temp"+pid,"w")
for h_chrom in h_dict:
	print "Starting thread %s" % pid
	for h_id in h_dict[h_chrom]:
		for p_chrom in p_dict:
			for p_pos in p_dict[p_chrom]:

				tab = tools.create_table(p_dict[p_chrom][p_pos],h_dict[h_chrom][h_id])
#				pval = tools.chisq(tab)
#				if pval<0.05:
				out.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (h_chrom,id2pos[h_id],h_id,p_chrom,p_pos,tab[0][0],tab[1][0],tab[0][1],tab[1][1],tab[0][2],tab[1][2]))
out.close()
print "Thread %s finished" % pid
