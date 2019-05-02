import camelot
import pandas as pd
#read the pdf for tables

tables = camelot.read_pdf("/Users/tiaborrego/Desktop/TCM_final/pdfs")

for table in tables:
	table.to_excel("lambert.xlsx", index = FALSE)