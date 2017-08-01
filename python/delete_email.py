#!/usr/bin/python

import imaplib
import getpass
import sys
import base64
from Crypto.Cipher import AES


'''
usage: python delete_email.py  fileNameList='listOfKeywordsToBeDeleted'
'''

username = raw_input("Enter your GMail username:")
pwd = getpass.getpass("Enter your password: ")


args = dict([arg.split('=') for arg in sys.argv[1:]])


#print ("Logging into gmail using user %s\n" %args['username'])
print ("Logging into gmail using user %s\n" %username)

imapServerConnection = imaplib.IMAP4_SSL('imap.gmail.com')

#imapServerConnectionMessage = imapServerConnection.login(args['username'], pwd)
imapServerConnectionMessage = imapServerConnection.login(username, pwd)
print(imapServerConnectionMessage)

#print("possible lists are as below")
#print imapServerConnection.list()

print ("using Inbox")
imapServerConnection.select("inbox")

with open(args['fileNameList'],'r') as f:
    for sender in f:
        sender = sender.strip()
        #print ("searching mails from user %s " % args['sender'])
        print ("searching mails from user %s " % sender)

        result_status, email_ids = imapServerConnection.search(None, '(FROM "%s")' % sender)
        #result_status, email_ids = imapServerConnection.search(None, '(FROM "%s")' % args['sender'])
        #result_status, email_ids = imapServerConnection.search(None, '(FROM ladder")')

        email_ids =  email_ids[0].split()

        if len(email_ids) == 0:
            print ("no emails found ......finishing")
        else:
            print("Found %d email or emails from user %s , moving to thrash" % (len(email_ids),sender))

        for emailItems in email_ids:
            print("moving %s" % emailItems)
            imapServerConnection.store(emailItems, '+X-GM-LABELS', '\\Trash')
    
imapServerConnection.expunge()

print("Done ........")


