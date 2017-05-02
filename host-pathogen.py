#! /usr/bin/python
from __future__ import division
import sys
import subprocess
import os
from tqdm import tqdm
from collections import defaultdict
import json

if len(sys.argv)!=6:
	print "host-pathogen.py <host_bfile> <path_matrix> <out_prefix> <samples> <threads>"
	quit()


scriptDir = os.path.dirname(os.path.realpath(__file__))


def reduce_mat(filename,newfile,idxname,samples):
	print "Reducing pathogen matrix"
	O = open(newfile,"w")
	reduced_mat = defaultdict(list)
	for l in tqdm(open(filename)):
		arr = l.rstrip().split()
		if l[0]=="#":
			sample_idx = [arr.index(s) for s in samples]
			continue
		seqline = "\t".join([arr[i] for i in sample_idx])
		reduced_mat[seqline].append(arr[:5])
	cnt = 0
	variant_ids = {}
	for seqline in reduced_mat:
		temp_arr = reduced_mat[seqline]
		var_id = "pathogen_variant_%s"%cnt
		variant_ids[var_id] = temp_arr
		cnt+=1
		O.write("%s\t%s\n" % (var_id,seqline))
	O.close()
	json.dump(variant_ids,open(idxname,"w"))

def reduce_tped(h_prefix,newfile,idxname,samples):
	print "Reducing host tped"
	O = open(newfile,"w")	
	tped = h_prefix+".tped"
	tfam = h_prefix+".tfam"
	tfam_samples = [l.split()[1] for l in open(tfam).readlines()]
	sample_idx = [tfam_samples.index(x) for x in samples]
	reduced_tped = defaultdict(list)
	for l in tqdm(open(tped)):
		arr = l.rstrip().split()
		seqline = []
		for j in sample_idx:
			i = j*2 + 4

			if arr[i]=="0" and arr[i+1]=="0":
				seqline.append("9")
			elif  arr[i]=="1" and arr[i+1]=="1":
				seqline.append("0")
			elif  arr[i]=="1" and arr[i+1]=="2":
				seqline.append("1")
			elif  arr[i]=="2" and arr[i+1]=="1":
				seqline.append("1")
			elif arr[i]=="2" and arr[i+1]=="2":
				seqline.append("2")
			else:
				print arr[i]
				print arr[i+1]
				print "ERROR!"
				quit()
		seqline = "\t".join(seqline)	
		reduced_tped[seqline].append(arr[:4])
	cnt = 0
	variant_ids = {}
	for seqline in reduced_tped:
		temp_arr = reduced_tped[seqline]
		var_id = "host_variant_%s"%cnt
		variant_ids[var_id] = temp_arr
		cnt+=1
		O.write("%s\t%s\n" % (var_id,seqline))
	O.close()
	json.dump(variant_ids,open(idxname,"w"))


h_prefix = sys.argv[1]
p_mat = sys.argv[2]
prefix = sys.argv[3]
samples = [x.rstrip() for x in open(sys.argv[4]).readlines()]
threads = sys.argv[5]


reduced_pathogen_mat = "%s.pathogen.reduced" % (prefix)
reduced_host_mat = "%s.host.reduced" % (prefix)
host_idx = "%s.host_idx.json" % (prefix)
pathogen_idx = "%s.pathogen_idx.json" % (prefix)

reduce_mat(p_mat,reduced_pathogen_mat,pathogen_idx,samples)
reduce_tped(h_prefix,reduced_host_mat,host_idx,samples)


cmd = subprocess.Popen("wc -l %s" % reduced_host_mat,shell=True,stdout=subprocess.PIPE)
for l in cmd.stdout:
	file_len = int(l.split()[0])


threads = int(threads)
lines_per_thread = int(file_len/threads)+1

with open("xargs.txt","w") as o:
	for i in range(threads):
		start = i*lines_per_thread
		if start>=file_len:
			break
		end = start+lines_per_thread-1
		for j in range(start,end):
			if j>file_len:
				end==j
				break
		o.write(" %s %s %s %s %s %s" % (reduced_host_mat,reduced_pathogen_mat,prefix,i,start,end))


subprocess.call("cat xargs.txt | xargs -n6 -P%s %s/worker.py" % (threads,scriptDir),shell=True)
subprocess.call("cat `ls %s.temp*` > %s.results.gz" %(prefix,prefix),shell=True)
subprocess.call("rm %s.temp*" % (prefix),shell=True)

