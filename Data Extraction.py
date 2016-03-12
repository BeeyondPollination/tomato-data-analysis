
# coding: utf-8

# In[1]:

# get_ipython().magic(u'matplotlib inline')
import pandas as pd
import numpy as np
import os
import re

# In[ ]:
dataFolderPath = 'D:\\System Folders\\Documents\\GitHub\\tomato-data-analysis'
files = os.listdir(dataFolderPath)
fileslist = []
#print files
for i in range(len(files)):
    datafile = files[i]
    print datafile
    if datafile.startswith("data_set"):
        #print datafile
        fileslist += [datafile]

print fileslist

dataList = []

for file in fileslist:
    day = [int(s) for s in re.findall(r'\d+',file)]
    print day
    #print dataFolderPath+file
    df = pd.read_csv(dataFolderPath + '\\' + file)
    df = df.fillna(0)
    df.columns = [c.replace(' ', '_') for c in df.columns]
    #df.columns = [c.replace('(Y/N)', '') for c in df.columns]
    del df['Treated(Y/N)']
    del df['Difference']
    df['Test_Day'] = day * df.Device.count()

    let2num = lambda x : ord(x)-0x40
    df.Device = df.Device.apply(let2num)

    dataList.append(df)

allData = pd.concat(dataList,ignore_index=True)

allData.to_csv(dataFolderPath + '\\consolidatedData.csv',index=False)

# In[ ]:



