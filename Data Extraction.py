
import pandas as pd
import numpy as np
import os
import re
from datetime import date

today = date.today()

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

for fileName in fileslist:
    # print fileName
    testDate = [int(s) for s in re.findall(r'\d+',fileName)]
    # print testDate
    # print dataFolderPath+file
    df = pd.read_csv(dataFolderPath + '\\' + fileName)
    df = df.fillna(0)
    df.columns = [c.replace(' ', '_') for c in df.columns]
    # df.columns = [c.replace('(Y/N)', '') for c in df.columns]
    if 'Treated(Y/N)' in df.columns:
        del df['Treated(Y/N)']
    if 'Difference' in df.columns:
        del df['Difference']

    if 'Broken_Sets' not in df.columns:
        df['Broken_Sets'] = [0] * df.Device.count()
    if 'Out_of_Sequence' not in df.columns:
        df['Out_of_Sequence'] = [0] * df.Device.count()

    df['Test_Year'] = testDate[0]
    df['Test_Month'] = testDate[1]
    df['Test_Day'] = testDate[2]

    print df.columns

    def let2num(x):
        "This converts a device letter to a number"
        deviceNum = ord(x)-0x40
        if deviceNum > 4:
            deviceNum -= 1
        return deviceNum

    for letter in df.Device:
        if isinstance(letter,int):
            print fileName
            print letter

    df.Device = df.Device.apply(let2num)

    dataList.append(df)

allData = pd.concat(dataList, ignore_index=True)

print allData.columns
saveFileName = '\\consolidatedData'+today.isoformat()+'.csv'
print saveFileName

allData.to_csv(dataFolderPath + saveFileName,index=False)



