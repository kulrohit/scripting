#!/usr/bin/env python
import csv
import glob
import gzip
import io
import logging
import optparse
import os
import sys
from datetime import timedelta, datetime

# V1.0 - Initial version

# Initialize logging
logging.basicConfig(format='%(asctime)s  %(levelname)s mediamathid_sync2redshift.py %(message)s', level=logging.INFO)


def processMediamathFiles(procdate, logpath, csvpath):
    logging.info("Process starts for date %s" % (procdate));
    files = glob.glob("%s/*%s*.log.gz" % (logpath, procdate))  # read all files in folder
    for file in files:
        logging.info("Started reading file %s" % (file));
        gz_reader = gzip.open(file, mode='rb')  # read log.gz file
        filecontent = io.BufferedReader(gz_reader)

        csvfilename = os.path.basename(file).split('.')[0]  # fetch file name except extension
        date = datetime.strptime(procdate, '%Y%m%d').strftime('%Y-%m-%d')  # date formatting

        logging.info("Started writing data in file %s.csv" % (csvfilename));
        csvfile = open("%s/%s.csv" % (csvpath, csvfilename), 'w')  #
        csvwriter = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        csvwriter.writerow(["refreshdate", "pkMediaMathID", "pkMCategoryID"])
        lines = filecontent.readlines()
        logging.info("Found number of records %s" % (len(lines)));
        if (len(lines) > 0):
            for line in lines:
                row = line.strip('\n')
                if (row):
                    categories = row.split("\t")  # split row using tab
                    mmid = categories.pop(0)  # remove and return 0th position value i.e. MediaMathID
                    for cat in categories:  # loop thru remaining categories
                        csvwriter.writerow([date, mmid, cat])  # write rows in csv

            csvfile.close()
            logging.info("Completed writing data in file %s.csv" % (csvfilename));


def _init(date, logpath, csvpath):
    if (isinstance(date, datetime)):
        yesterdaydate = date - timedelta(1)  # return date object
        procdate = yesterdaydate.strftime('%Y%m%d')  # formatting date
    else:
        procdate = datetime.strptime(date, '%Y%m%d').strftime('%Y%m%d')

    try:
        processMediamathFiles(procdate, logpath, csvpath)  # processing mediamath files
        logging.info("Completed Mediamath file writing.");
        sys.exit(0)
    except Exception, ex:
        logging.error("Unable to complete Mediamath file writing.");
        logging.error(ex)
        sys.exit(1)


def main():
    """
    Main method parses the options.
    """
    CURRENT_DATE = datetime.today()

    optparser = optparse.OptionParser(prog='mediamathid_sync2redshift.py', version='1.0',
                                      description='\x1B[1mDesc: Script reads mediamath log files and transform into csv. See below options;\x1B[0m',
                                      usage='\x1B[1m %prog -d [date format {YYYYMMDD}] ' + \
                                            '-l [source log dir path] -c [destination csv dir path] \x1B[0m')
    optparser.add_option('-d', '--date', dest='date', default=CURRENT_DATE,
                         help="date should be in {YYYYMMDD} format e.g. 20170419")
    optparser.add_option('-l', '--logpath', dest='logpath', help="path for reading oracle log.gz files")
    optparser.add_option('-c', '--csvpath', dest='csvpath', help="path for writing csv files")

    options, arguments = optparser.parse_args()

    if options.date and options.logpath and options.csvpath:
        _init(options.date, options.logpath, options.csvpath)
    else:
        print "\x1B[37;41;1mError: Some arguments missing; Please see help below; \x1B[0m\n"
        optparser.print_help()


if __name__ == "__main__":
    main()
