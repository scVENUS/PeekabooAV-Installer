#!/bin/sh -e

varprefix=POSTFIX_MAIN_CF_
env | grep "^$varprefix" | sed "s,^$varprefix,," |
		while IFS== read parameter value ; do
	parameter=$(echo "$parameter" | tr 'A-Z' 'a-z')
	postconf $2 -e "$parameter=$value"
done

varprefix=POSTFIX_VIRTUAL
env | grep "^$varprefix" | sed "s,^$varprefix,," |
		while IFS== read parameter value ; do
	echo "$value" >> /etc/postfix/virtual
done

exec postfix -v start-fg
