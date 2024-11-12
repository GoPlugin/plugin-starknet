#!/usr/bin/env bash

echo "Cleaning up core containers.."

echo "Checking for existing 'plugin.core' docker containers..."

for i in {1..5}
do
	echo " Checking for plugin.core.$i"
	dpid=$(docker ps -a | grep plugin.core.$i | awk '{print $1}')
	if [ -z "$dpid" ]; then
		echo "No docker core container running."
	else
		docker kill $dpid
		docker rm $dpid
	fi
done

echo "Cleanup finished."
