import csv, gzip, os, glob, sys, io, json, sys
from datetime import timedelta, datetime

# log_file_path = "/Users/mithunm/D_Drive/CisionProject/python_scripts"
# csv_file_path = "/Users/mithunm/D_Drive/CisionProject/python_scripts"

# current_date = datetime.today() # return date object
# current_date_fmt = datetime.today().strftime('%Y%m%d') # return date object
# yesterday_date = current_date - timedelta(1) # return date object
# processing_date_fmt = yesterday_date.strftime('%Y%m%d') # formatting date


def processFiles(inputpath, outputpath):
    files = glob.glob("%s/multimedia-*.json" % (inputpath))
    for file in files:
        csv_file_name = os.path.basename(file).split('.')[0] # fetch file name except extension
        csv_file = open("%s/%s.csv" % (outputpath, csv_file_name), 'w') #
        csv_writer = csv.writer(csv_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        csv_writer.writerow(["fileurlid", "type", "sn", "sd"])

        data = json.load(open(file))
        for d in data['request']['multimedia']:
            csv_writer.writerow([d["fileurlid"], d["type"], d["sn"], d["sd"]]) # write rows in csv

        csv_file.close()

if __name__ == "__main__":
    if len(sys.argv) >= 2:
        inputpath = sys.argv[1]
        outputpath = sys.argv[2]

        processFiles(inputpath, outputpath)

        sys.exit(0)
    else:
        sys.exit(1)
