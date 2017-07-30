#!/bin/bash

if [ $# -eq 0 ]; then echo "Please provide the name or id of the docker container!" && exit; fi

	echo "
			Modifying docker container '$1' ...

		"
docker cp specifyweb/frontend/js_src/lib/specifyapi.js "$1:/usr/local/specify7/specifyweb/frontend/js_src/lib/"
docker cp specifyweb/frontend/js_src/lib/weblinkbutton.js "$1:/usr/local/specify7/specifyweb/frontend/js_src/lib/"

	echo "
			Rebuilidung Specify 7 web application ...
			
		"
	
docker exec -it "$1" /bin/bash -c 'cd /usr/local/specify7 && make all'

	echo "
			Restarting docker container '$1' ...
			
		"
docker restart "$1"

	echo "
		Done!
		
		"