#!/usr/bin/python

import psycopg2
import sys
import collections
import jprops
import logging
import os

#Initialize logging
logging.basicConfig(format='%(asctime)s  %(levelname)s vacuum.py  %(message)s', level=logging.INFO)
def main(ifile):
  logging.info("Using property file %s",ifile)
  with open(ifile) as fp:
    properties = jprops.load_properties(fp, collections.OrderedDict)
    con = psycopg2.connect(host=properties['redshift.dbhost'], port=properties['redshift.port'], user=properties['redshift.username'], password=properties['redshift.password'], database=properties['redshift.db'])
    logging.info("Connecting to DB using %s %s %s %s" ,properties['redshift.dbhost'],properties['redshift.port'],properties['redshift.username'],properties['redshift.db'])
    con.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
    cur = con.cursor()
    tables = properties['redshift.tables'].split(",")
    for table in tables:
		  logging.info("vacuuming  on %s" %table)
		  cur.execute("vacuum delete only %s;" %table)
    cur.close();

if __name__ == "__main__":
	if len(sys.argv) >= 2:
		ifile = sys.argv[1]
		if os.path.isfile(ifile) == False:
			raise Exception('File specified does not exist.')
		main(ifile)
	else:
		logging.error('Please specify file and date for folder.')
		logging.error('Example: wtedbmaint.py <property file>')
		sys.exit(0)
