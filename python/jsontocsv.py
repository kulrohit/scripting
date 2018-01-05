import csv, gzip, os, glob, sys, io, json
from datetime import timedelta, datetime

def processFile(inputfile, outputfile):
    csv_file = open(outputfile, 'w') #
    csv_writer = csv.writer(csv_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    csv_writer.writerow(["sn", "sd", "fileurlid", "type"])

    data = json.load(open(inputfile))
    for d in data['request']['multimedia']:
        csv_writer.writerow([d["sn"], d["sd"], d["fileurlid"], d["type"]]) # write rows in csv

    csv_file.close()

if __name__ == "__main__":
    if len(sys.argv) >= 2:
        inputfile = sys.argv[1]
        outputfile = sys.argv[2]

        processFile(inputfile, outputfile)

        sys.exit(0)
    else:
        sys.exit(1)