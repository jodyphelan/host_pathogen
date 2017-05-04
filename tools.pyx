from __future__ import division
from collections import defaultdict
from cpython cimport array
import array
import numpy as np
from scipy.stats import chisquare

cpdef list create_table(char s1[],char s2[]):
	cdef int l = len(s1)
	cdef int one_one = 0
	cdef int one_zero = 0
	cdef int zero_one = 0
	cdef int zero_zero = 0
	cdef int zero_two = 0
	cdef int one_two = 0
	print len(s1)
	print len(s2)
	for i in range(0,l):
		if s1[i]=="0" and s2[i]=="0":
			zero_zero+=1
		elif s1[i]=="0" and s2[i]=="1":
			zero_one+=1
		elif s1[i]=="1" and s2[i]=="0":
			one_zero+=1
		elif s1[i]=="1" and s2[i]=="1":
			one_one+=1
		elif s1[i]=="0" and s2[i]=="2":
			zero_two+=1
		elif s1[i]=="1" and s2[i]=="2":
			one_two+=1
	return [[zero_zero,zero_one,zero_two],[one_zero,one_one,one_two]]
		
cpdef chisq(tab):
	obs = tab 
	exp = np.outer([obs[0][0]+obs[0][1]+obs[0][2],obs[1][0]+obs[1][1]+obs[1][2]],[obs[0][0]+obs[1][0],obs[0][1]+obs[1][1],obs[0][2]+obs[1][2]])/np.sum([obs[0][0]+obs[1][0],obs[0][1]+obs[1][1],obs[0][2]+obs[1][2]])
	return chisquare(obs,f_exp=exp,axis=None)[1]

cpdef float get_af(char s[]):
	cdef int l = len(s)
	cdef int ones = 0
	cdef int zeros = 0
	for i in range(0,l):
		if s[i]=="1":
			ones+=1
		elif s[i]=="0":	
			zeros+=1
	return ones/(ones+zeros)


cpdef str recode_plink(char s[]):
	cdef int l = len(s)
	cdef array.array arr = array.array('c',["9"]*int(l/2))
	for j in xrange(l):
		i = int(j/2)
		if s[j]=="0" or s[j+1]=="0":
			arr[i] = "9"
		elif s[j]=="1" and s[j+1]=="1":
			arr[i] = "0"
		elif s[j]=="1" and s[j+1]=="2":
			arr[i] = "1"
		elif s[j]=="2" and s[j+1]=="1":
			arr[i] = "1"
		elif s[j]=="2" and s[j+1]=="2":
			arr[i] = "2"
	return arr.tostring()

def tab2lists(arr):
	x = []
	y = []
	for i in range(int(arr[5])):
		x.append(0)
		y.append(0)
	for i in range(int(arr[6])):
		x.append(0)
		y.append(1)
	for i in range(int(arr[7])):
		x.append(1)
		y.append(0)
	for i in range(int(arr[8])):
		x.append(1)
		y.append(1)
	for i in range(int(arr[9])):
		x.append(2)
		y.append(0)
	for i in range(int(arr[10])):
		x.append(2)
		y.append(1)
	return x,y
