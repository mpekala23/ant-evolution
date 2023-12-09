"""
Takes in a .out file produced by netlogo and makes it a proper csv for pandas
"""


import csv
from io import StringIO


def out2csv(fname: str, out_fname: str):
    with open(fname) as fin:
        text = ""
        for line in fin.readlines():
            clean_line = line[1:-4]
            text += f"{clean_line}\n"
    headers = ["tick", "scent_id", "energy", "x", "y,"]
    # Convert the input data into a CSV-formatted string
    csv_data = StringIO()
    csv_writer = csv.writer(csv_data)
    csv_writer.writerow(headers)
    csv_reader = csv.reader(StringIO(text), delimiter=" ")
    for row in csv_reader:
        csv_writer.writerow(row)
    csv_data.seek(0)
    with open(out_fname, "w") as fout:
        fout.write(csv_data.read())
