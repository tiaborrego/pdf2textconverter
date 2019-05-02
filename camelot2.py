import camelot
tables = camelot.read_pdf('foo.pdf')

tables.export('foo.csv',f='csv',compress=True)
tables[0]
tables[0].parsing_report
tables[0].to_csv('foo.csv')
tables[0].df