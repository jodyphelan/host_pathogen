#! /usr/bin/python
from __future__ import division
import sys
import subprocess
import os


if len(sys.argv)!=5:
	print "<host-pathogen.py <host_bfile> <path_matrix> <out_prefix> <threads>"
	quit()

script,h_prefix,p_mat,outfile,threads = sys.argv

scriptDir = os.path.dirname(os.path.realpath(__file__))


cmd = subprocess.Popen("wc -l %s.tped" % h_prefix,shell=True,stdout=subprocess.PIPE)
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
		o.write(" %s %s %s %s %s %s" % (h_prefix,p_mat,outfile,i,start,end))

subprocess.call("cat xargs.txt | xargs -n6 -P%s %s/worker.py" % (threads,scriptDir),shell=True)

subprocess.call("cat `ls %s.temp*` > %s.results" %(outfile,outfile),shell=True)
