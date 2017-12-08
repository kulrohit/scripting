#!/bin/bash
# A simple email script that uses mutt to send out emails and also attachements. 
# This is a flexible script with options to use a configuration file and / or command line arguements. The command line arguement overrides the properties in 
# in configuration file. 
# Funtion for standardised Script logging
f_log()
{
        echo -e "`date` - $1"
}

f_usage()
{
	f_log "Usage: $0  -s <email subject> -t <to email address> -b <body of message > -a <path of file to attach> -c <configuration file>"
	f_log "Options can be passed either in configuration file or individually. Its also possible to use both where the individual options take precedence over configuraiton file"
}



while getopts b:s:t:a:c:h arg
do	case "$arg" in
	c)	a_cfgfile="$OPTARG";;
	t)	a_toemail="$OPTARG";;
	s)	a_subject="$OPTARG";;
	b)	a_body="$OPTARG";;
	a)	a_fileattachment="$OPTARG";;
	\?|h)	f_usage $0
		exit 1;;
	esac
done

if [[ ! -z $a_cfgfile ]]
then
    . $a_cfgfile
fi

if [[  -z $a_toemail ]]
then
	a_toemail=$TOEMAIL
fi

if [[  -z $a_subject ]]
then
	a_subject=$SUBJECT
fi

if [[  -z $a_body ]]
then
        a_body=$MESSAGE
fi

if [[  -z $a_fileattachment ]]
then
        a_fileattachment=$ATTACHMENT
fi

if [[  -z $a_toemail ]] || [[ -z $a_subject ]] || [[ -z $a_body ]]; then 
	f_usage;
	exit 2;
fi

if [[ -z $a_fileattachment ]]; then
#	echo $MESSAGE | mail -s "$SUBJECT" "$TOEMAIL" 
	echo $MESSAGE | /usr/bin/mutt -s "$a_subject" "$a_toemail" 
else
#	(cat $MESSAGE; uuencode $ATTACHMENT $ATTACHMENT) | mail $TOEMAIL
        echo $MESSAGE | /usr/bin/mutt -s "$a_subject" "$a_toemail" -a $a_fileattachment
fi
