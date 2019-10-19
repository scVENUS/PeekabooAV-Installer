#!/usr/bin/env python3
# Based on: 	https://gist.github.com/athoune/91b1e57df2e347add5d48e38e31ae1aa
# Credit: 		https://gist.github.com/athoune

import subprocess
import re
import json

from pypred import Predicate


SPACE = re.compile(r"\s+")

def mailq():
	mq = subprocess.Popen(['mailq'], stdout=subprocess.PIPE)
	buffer = []
	prems = True
	for line in mq.stdout:
		if prems:
			prems = False
			continue
		buffer.append(line[:-1])
		if line == b'\n':
			# Each entry shows the queue file ID, message size, arrival time, sender, and the recipients that still need to be delivered.
			meta = SPACE.split(buffer[0].decode("utf8"))
			id = meta[0]
			size = int(meta[1])
			sender = meta[-1]
			date = " ".join(meta[2:-1])
			dest = buffer[2].decode('utf8').strip()
			# FIXME sometime, there is more than one dest
			yield id, size, date, sender, buffer[1].decode('utf8'), dest
			buffer = []


def main():
	import sys
	if len(sys.argv) == 2:
		p = Predicate(sys.argv[1])
		if not p.is_valid():
			for error in p.errors()['errors']:
				print(error)
			return
	else:
		p = None
	rows = []
	for  id, size, date, sender, msg, dest in mailq():
		
		colsObject = {
			"cols": [
				{"value": id},
				{"value": size},
				{"value": date},
				{"value": sender},
				{"value": dest}
			]
		}
		rows.append(colsObject)
	
	#doc = list(id, size, date, sender, msg, dest)
	
	if p == None or p.evaluate(doc):
		rowsObject = {
			"rows": rows
		}
		hrowsColsObject = {
			"cols": [
				{"value": "ID"},
				{"value": "Size"},
				{"value": "Date"},
				{"value": "Sender"},
				{"value": "Recipient"}
			]
		}
		
		hrowsColsArray = []
		hrowsColsArray.append(hrowsColsObject)
	
		hrowsObject = {
			"hrows": hrowsColsArray
		}
		
		returnString = json.dumps(hrowsObject)[1:-1] + ", " + json.dumps(rowsObject)[1:-1]
		
		print(returnString)
		
	
if __name__ == '__main__':
	main()
