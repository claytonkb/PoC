import numpy as np
import pandas as pd
import sys

# CSV-Magick :: intersect
#
# Takes set-subtraction: csvL.colX - csvR.colY
# Returns all rows in csvA that land within the intersection; if only one
#   column name X provided, then Y is set to X

num_args = len(sys.argv) - 1

if(num_args < 3):
    print("Usage: python cm_subtract.py Lfile.csv Rfile.csv Lcol [Rcol]")
    sys.exit()

csv_left_filename  = str(sys.argv[1])
csv_right_filename = str(sys.argv[2])

csv_left_column  = str(sys.argv[3])

#if(num_args == 4):
#    csv_right_column = str(sys.argv[4])
#elif(num_args == 3):
#    csv_right_column = str(sys.argv[3])

csv_right_column = str(sys.argv[num_args]) # this just happens to work

if(csv_left_filename == csv_right_filename):
    left_data  = pd.read_csv(csv_left_filename, encoding='utf-8')
    right_data = left_data
else:
    left_data  = pd.read_csv(csv_left_filename, encoding='utf-8')
    right_data = pd.read_csv(csv_right_filename, encoding='utf-8')

left_column  = list(left_data[csv_left_column])
right_column = list(right_data[csv_right_column])

right_index = {}

for right_value in right_column:
    right_index[right_value] = 1

result = pd.DataFrame()

for left_value in left_column:
    if(left_value not in right_index):
        rows = left_data[left_data[csv_left_column] == left_value]
        result = result.append(rows)

print(result.to_csv())

#https://pandas.pydata.org/pandas-docs/stable/getting_started/10min.html
#https://www.shanelynn.ie/using-pandas-dataframe-creating-editing-viewing-data-in-python/
#https://pandas.pydata.org/pandas-docs/stable/reference/api/pandas.DataFrame.to_csv.html

# Clayton Bauman 2020

