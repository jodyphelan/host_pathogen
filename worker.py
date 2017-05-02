#! /home/jody/software/anaconda2/bin/python
from __future__ import division
import sys
import tools
from collections import defaultdict 
import gzip

script,h_mat,p_mat,outfile,pid,h_start_idx,h_stop_idx = sys.argv


p_dict = defaultdict(dict)
h_dict = defaultdict(dict)
h_start_idx = int(h_start_idx)
h_stop_idx = int(h_stop_idx)

id2pos = {}
with open(h_mat) as f:
	for i,l in enumerate(f):
		if i>=h_start_idx and i<=h_stop_idx:
			temp = l.rstrip().split()
			# expect vector with variant_id and calls [0,1,2,9] 9 is missing data
			h_dict[temp[0]] = "".join(temp[1:])

with open(p_mat) as f:
	for l in f:
		temp = l.rstrip().split()
		p_dict[temp[0]] = "".join(temp[1:])



with gzip.open(outfile+".temp"+pid+".gz","wb") as out:
	print "Starting thread %s" % pid

	for h_id in h_dict:
		for p_id in p_dict:
			tab = tools.create_table(p_dict[p_id],h_dict[h_id])
			out.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (h_id,p_id,tab[0][0],tab[1][0],tab[0][1],tab[1][1],tab[0][2],tab[1][2]))

print "Thread %s finished" % pid
