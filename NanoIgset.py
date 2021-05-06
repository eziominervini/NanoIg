#!/usr/bin/python

import sys, os


def pypath(folder):
    pyfolder=''
    pyfolder=folder.replace('\\','/')
    pyfolder=pyfolder.replace('\\\\','/')
    
    return pyfolder

path=pypath(sys.argv[1])
run=pypath(sys.argv[2])

BClist = [f for f in os.listdir(path+"/fastq")]
BClist.sort()

# work directory setting

os.chdir(path) 

os.mkdir(path +'/PIPE')
os.mkdir(path +'/PIPE/Clonality')


for subdir, dirs, files in os.walk(path+'/fastq'):
    for dir in dirs:
        os.mkdir(os.path.join(path + '/PIPE/'+ dir))
        os.mkdir(os.path.join(path + '/PIPE/Clonality/'+ dir))
        print(os.path.join(path + '/PIPE/Clonality/'+ dir))
        

def find(name, path):
    for root, dirs, files in os.walk(path):
        if name in files:
            return os.path.join(root, name)

#Run Linux script

Bashlist=[]

for BC in BClist:
    sh=run.replace("/NanoIgset.py", "") + '/PipeIg.sh'
    #sub1="bash -c " + '"' + convertpath(sh) + " -i " + convertpath(path) + " -b " + BC + " -r " + convertpath(run) + '"'
    sub1="bash " + sh + " -i " + path + " -b " + BC + " -r " + run

    Bashlist.append(sub1)
    
with open(run+'/bashexec.txt', 'w') as f:
    for item in Bashlist:
        f.write("%s\n" % item)
