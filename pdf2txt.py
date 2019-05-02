#create two folders, one for pdfs and one for text files
#set your directory to the folder with these folders
#may have to install pip and pdfminer

from cStringIO import StringIO
from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter
from pdfminer.converter import TextConverter
from pdfminer.layout import LAParams
from pdfminer.pdfpage import PDFPage
import os
import sys, getopt
import codecs
import shutil
import camelot
import pandas as pd

#converts pdf, returns its text content as a string
#def getText():
 #   with codecs.open("/Users/tiaborrego/Desktop/TCM_final/pdfs", "r", encoding='utf-8') as infile:
  #      allText = infile.read()
   # return allText

def convert(fname, pages=None):
    if not pages:
        pagenums = set()
    else:
        pagenums = set(pages)

    output = StringIO()
    manager = PDFResourceManager()
    converter = TextConverter(manager, output, laparams=LAParams())
    interpreter = PDFPageInterpreter(manager, converter)

    infile = file(fname, 'rb')
    for page in PDFPage.get_pages(infile, pagenums):
        interpreter.process_page(page)
    infile.close()
    converter.close()
    text = output.getvalue()
    output.close
    return text 
   
def convertMultiple(pdfDir, txtDir):
    if pdfDir == "": pdfDir = os.getcwd() + "\\" #if no pdfDir passed in 
    for pdf in os.listdir(pdfDir): #iterate through pdfs in pdf directory
        fileExtension = pdf.split(".")[-1]
        if fileExtension == "pdf":
            pdfFilename = pdfDir + "/" + pdf 
            text = convert(pdfFilename) #get string of text content of pdf
            textFilename = txtDir + pdf + ".doc"
            textFile = open(textFilename, "w") #make text file
            textFile.write(text) #write text to text file
            shutil.move(textFilename, txtDir)
            
#def convertAgain(pdfDir, excelDir):
 #   if pdfDir == "": pdfDir = os.getcwd() + "\\"
  #  for pdf in os.listdir(pdfDir): #iterate through pdfs in pdf directory
   #     fileExtension = pdf.split(".")[-1]
    #    if fileExtension == "pdf":
     #       #tables = camelot.read_pdf(pdfFilename)
      #      tables = wrapper.convert_into_by_batch("/Users/tiaborrego/Desktop/TCM_final/pdfs", output_format = "xlsx", java_options=None,**kwargs)
       #     for table in tables:
        #        tableFileName = table.to_excel(excelDir + pdf + ".xlsx", index = FALSE)
            ##tableFilename = excelDir + pdf + ".xlsx"
          ##  tableFile = open(tableFilename, "w")
          ##  tableFile.write(tables)
         #   shutil.move(tableFilename, excelDir) #move files to the excel directory

	#textFile.close

pdfDir = "/Users/tiaborrego/Desktop/TCM_final/pdfs"
txtDir = "/Users/tiaborrego/Desktop/TCM_final/text"
#excelDir = "/Users/tiaborrego/Desktop/TCM_final/tables"
convertMultiple(pdfDir, txtDir)