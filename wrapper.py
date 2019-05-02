import tabula

from tabula import wrapper

tables = wrapper.convert_into_by_batch("/Users/tiaborrego/Desktop/TCM_final/pdfs", output_format = "xlsx", java_options=None,**kwargs)