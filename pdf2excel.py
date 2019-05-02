# pip install tornado
# pip install nose
# pip install camelot-py[cv]
# if you get an error try using the --user (pip install --user camelot-py[cv])
#for cannot uninstall numpy error use pip install --ignore-installed bCNC
# if encountering six error with system integrity use sudo -H pip install --ignore-installed six

import camelot

for i in range(30,35):
    print (i)
    tables = camelot.read_pdf("/Users/tiaborrego/Desktop/TCM_final/MGI_Disruptive_technologies_Full_report_May2013.pdf", pages='%d' %  i)
    try:
        print (tabulate(tables[0].df))
        print (tabulate(tables[1].df))
    except IndexError:
        print('NOK')