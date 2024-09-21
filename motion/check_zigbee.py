#!/usr/bin/python3

import sys
import json
#import time
from websocket import create_connection

try:
	ACCESS_TOKEN = sys.argv[1]
	entity_id = sys.argv[2]

	ws = create_connection("ws://localhost:8123/api/websocket")

	result =  ws.recv()

	ws.send(json.dumps({'type': 'auth', 'access_token': ACCESS_TOKEN}))

	result =  ws.recv()

	ident = 1

	ws.send(json.dumps({'id': ident, 'type': 'get_states'}))

	result =  ws.recv()

	#print(result)

	json_result = json.loads(result)

	# retrieve each device that was returned
	for device in json_result["result"] :
		if device["entity_id"] == entity_id:
			#print(device["entity_id"], device["state"])
			if device["state"] == "unavailable":
				sys.exit(1)
			else:
				sys.exit(0)

	sys.exit(1)
except Exception as e:
	print(e)
	sys.exit(1)
