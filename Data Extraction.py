
import pandas as pd
import numpy as np
import os
import re

dataFolderPath = 'D:\\System Folders\\Documents\\GitHub\\tomato-data-analysis'
files = os.listdir(dataFolderPath)
fileslist = []
#print files
for i in range(len(files)):
    datafile = files[i]
    print datafile
    if datafile.startswith("2016"):
        #print datafile
        fileslist += [datafile]

print fileslist

dataList = []

for file in fileslist:
    print file
    date = file.split('-',2)
    print date
    day = [int(s) for s in re.findall(r'\d+',file)]
    print day
    #print dataFolderPath+file
    df = pd.read_csv(dataFolderPath + '\\' + file)
    df = df.fillna(0)
    df.columns = [c.replace(' ', '_') for c in df.columns]
    #df.columns = [c.replace('(Y/N)', '') for c in df.columns]
    del df['Treated(Y/N)']
    del df['Difference']

    if 'Broken_Sets' not in df.columns:
        df['Broken_Sets'] = [0] * df.Device.count()

    df['Test_Day'] = day * df.Device.count()

    print df.columns

    let2num = lambda x : ord(x)-0x40
    df.Device = df.Device.apply(let2num)

    dataList.append(df)

allData = pd.concat(dataList,ignore_index=True)

#allData.to_csv(dataFolderPath + '\\consolidatedData.csv',index=False)



